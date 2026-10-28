import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/app_config.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/core/network/data_source.dart';
import 'package:smap/core/network/dio_provider.dart';
import 'package:smap/core/network/error_mapper.dart';
import 'package:smap/core/network/interceptors/log_interceptor.dart';
import 'package:smap/features/campus/data/campus_status_repository.dart';
import 'package:smap/features/campus/state/campus_status_providers.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/navigation/data/link_yaw_repository.dart';
import 'package:smap/features/navigation/state/link_yaw_controller.dart';
import 'package:smap/features/report/data/mock_report_repository.dart';
import 'package:smap/features/report/state/report_providers.dart';

void main() {
  group('환경 설정', () {
    test('dart-define이 없으면 dev·mock으로 실행한다', () {
      final config = AppConfig.fromEnvironment();
      expect(config.env, AppEnv.dev);
      expect(config.baseUrl, 'https://api.milkyway03.cloud');
      expect(config.useMock, isTrue);
      expect(config.logNetwork, isTrue);
    });

    test('prod에서는 네트워크 로그를 남기지 않는다', () {
      const prod = AppConfig(env: AppEnv.prod, baseUrl: 'x', useMock: false);
      expect(prod.logNetwork, isFalse);
    });

    test('Dio에 Base URL과 타임아웃을 넣는다', () {
      const config = AppConfig(
        env: AppEnv.prod,
        baseUrl: 'https://api.prod',
        useMock: false,
      );
      final dio = buildDio(config, readToken: () async => null);
      expect(dio.options.baseUrl, 'https://api.prod');
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 15));
      expect(
        dio.interceptors.whereType<MaskingLogInterceptor>(),
        isEmpty,
        reason: 'prod has no request log',
      );
    });
  });

  group('mock·API 구현 교체', () {
    const live = AppConfig(env: AppEnv.dev, baseUrl: 'x', useMock: false);
    const mock = AppConfig(env: AppEnv.dev, baseUrl: 'x', useMock: true);

    test('USE_MOCK이 꺼져 있고 API 구현이 있으면 API 구현을 쓴다', () {
      expect(
        selectDataSource(live, mock: () => 'mock', api: () => 'api'),
        'api',
      );
    });

    test('USE_MOCK이 켜져 있으면 API 구현이 있어도 mock을 쓴다', () {
      expect(
        selectDataSource(mock, mock: () => 'mock', api: () => 'api'),
        'mock',
      );
    });

    test('API 구현이 아직 없으면 mock으로 동작한다', () {
      expect(selectDataSource<String>(live, mock: () => 'mock'), 'mock');
    });

    test('기존 Repository들은 기본 설정에서 mock을 주입받는다', () {
      final c = ProviderContainer(
        overrides: [launchQueryProvider.overrideWithValue(const {})],
      );
      addTearDown(c.dispose);
      expect(c.read(reportRepositoryProvider), isA<MockReportRepository>());
      expect(
        c.read(campusStatusRepositoryProvider),
        isA<MockCampusStatusRepository>(),
      );
      expect(c.read(linkYawRepositoryProvider), isA<MockLinkYawRepository>());
    });

    test('설정을 바꾸면 같은 Dio·ApiClient가 새 Base URL로 다시 만들어진다', () {
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              env: AppEnv.prod,
              baseUrl: 'https://p',
              useMock: false,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(dioProvider).options.baseUrl, 'https://p');
      expect(c.read(apiClientProvider), isNotNull);
    });
  });

  group('로그 마스킹', () {
    test('민감한 헤더는 가리고 Bearer 스킴은 남긴다', () {
      final masked = maskHeaders({
        'Authorization': 'Bearer secret-token',
        'X-Admin-Key': 'admin-123',
        'Cookie': 'sid=1',
        'Accept': 'application/json',
      });
      expect(masked['Authorization'], 'Bearer ***');
      expect(masked['X-Admin-Key'], '***');
      expect(masked['Cookie'], '***');
      expect(masked['Accept'], 'application/json');
    });

    test('본문 안쪽의 토큰·비밀번호 필드도 가린다', () {
      final masked = maskBody({
        'query': '본관',
        'auth': {'access_token': 'a', 'refreshToken': 'b', 'password': 'c'},
        'list': [
          {'token': 'd', 'name': 'e'},
        ],
      });
      expect(masked, {
        'query': '본관',
        'auth': {
          'access_token': '***',
          'refreshToken': '***',
          'password': '***',
        },
        'list': [
          {'token': '***', 'name': 'e'},
        ],
      });
    });

    test('음성 파일은 바이트 대신 파일 이름만 남긴다', () {
      final masked = maskBody(
        FormData.fromMap({
          'target': 'DESTINATION',
          'audio': MultipartFile.fromBytes([1, 2, 3], filename: 'q.m4a'),
        }),
      );
      expect(masked, {
        'fields': {'target': 'DESTINATION'},
        'files': ['audio: q.m4a'],
      });
    });

    test('요청·응답 로그에 비밀 값이 남지 않는다', () async {
      final lines = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _EchoAdapter()
        ..interceptors.add(MaskingLogInterceptor(log: lines.add));
      await dio.post<Object?>(
        '/login',
        data: {'password': 'p@ss'},
        options: Options(headers: {'Authorization': 'Bearer t0k'}),
      );
      final log = lines.join('\n');
      expect(log, contains('→ POST https://api.test/login'));
      expect(log, contains('← 200 POST'));
      expect(log, isNot(contains('p@ss')));
      expect(log, isNot(contains('t0k')));
    });
  });

  test('Dio 밖의 오류도 공통 앱 오류로 바꾼다', () {
    expect(toAppException(const FormatException()), isA<ParseException>());
    expect(toAppException(StateError('x')), isA<UnknownException>());
    const same = NetworkException();
    expect(toAppException(same), same);
  });
}

class _EchoAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"success":true,"code":"OK","message":"","data":{"token":"t0k"}}',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}
