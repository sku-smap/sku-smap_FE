import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/api_client.dart';
import 'package:smap/core/network/app_config.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/core/network/dio_provider.dart';
import 'package:smap/core/network/interceptors/retry_interceptor.dart';

// Answers requests in memory so tests never reach a server
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.reply);

  final Future<ResponseBody> Function(RequestOptions options, int call) reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return reply(options, requests.length);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object?> _envelope(Object? data) => {
  'success': true,
  'code': 'COMMON_200_OK',
  'message': '성공',
  'data': data,
};

const _config = AppConfig(
  env: AppEnv.dev,
  baseUrl: 'https://api.test',
  useMock: false,
);

({ApiClient client, _FakeAdapter adapter}) _client(
  Future<ResponseBody> Function(RequestOptions options, int call) reply, {
  String? token,
}) {
  final dio = buildDio(_config, readToken: () async => token);
  final adapter = _FakeAdapter(reply);
  dio.httpClientAdapter = adapter;
  final retry = dio.interceptors.whereType<RetryInterceptor>().single;
  dio.interceptors[dio.interceptors.indexOf(retry)] = RetryInterceptor(
    dio,
    backoff: (_) => Duration.zero,
  );
  return (client: ApiClient(dio), adapter: adapter);
}

Never _throw(RequestOptions o, DioExceptionType type) =>
    throw DioException(requestOptions: o, type: type);

void main() {
  group('공통 응답 파싱', () {
    test('성공 envelope의 data를 꺼내 변환한다', () async {
      final (:client, :adapter) = _client(
        (_, _) async => _json(
          _envelope([
            {'id': 1, 'name': '본관'},
          ]),
        ),
      );
      final names = await client.get(
        '/api/v1/places',
        query: {'keyword': '본관'},
        decode: (data) => [
          for (final p in data! as List) (p as Map)['name'] as String,
        ],
      );
      expect(names, ['본관']);
      expect(
        adapter.requests.single.uri.toString(),
        'https://api.test/api/v1/places?keyword=%EB%B3%B8%EA%B4%80',
      );
    });

    test('data가 없는 응답도 처리한다', () async {
      final (:client, adapter: _) = _client(
        (_, _) async => _json(_envelope(null)),
      );
      await expectLater(
        client.put(
          '/api/v1/searches/1/selection',
          body: {'candidateId': 1},
          decode: ignoreData,
        ),
        completes,
      );
    });

    test('200이어도 success=false면 서버 오류 코드와 메시지를 담는다', () async {
      final (:client, adapter: _) = _client(
        (_, _) async => _json({
          'success': false,
          'code': 'SEARCH_400_INVALID',
          'message': '검색어를 입력해 주세요.',
          'data': null,
        }),
      );
      final error = await client
          .post('/api/v1/searches', body: {}, decode: ignoreData)
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(error, isA<ServerException>());
      final e = error! as ServerException;
      expect(e.code, 'SEARCH_400_INVALID');
      expect(e.message, '검색어를 입력해 주세요.');
    });

    test('envelope가 아니거나 data 모양이 다르면 파싱 오류다', () async {
      final notEnvelope = _client((_, _) async => _json({'hello': 1}));
      await expectLater(
        notEnvelope.client.get('/x', decode: (d) => d),
        throwsA(isA<ParseException>()),
      );

      final wrongShape = _client((_, _) async => _json(_envelope('text')));
      await expectLater(
        wrongShape.client.get('/x', decode: (d) => (d! as Map)['id']),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('오류 변환', () {
    test('오류 envelope의 상태·코드·메시지를 담는다 (404)', () async {
      final (:client, adapter: _) = _client(
        (_, _) async => _json({
          'success': false,
          'code': 'COMMON_404_NOT_FOUND',
          'message': '요청한 경로나 리소스를 찾을 수 없습니다.',
          'data': null,
        }, 404),
      );
      final error = await client
          .get('/nope', decode: ignoreData)
          .then<Object?>((_) => null, onError: (Object e) => e);
      expect(error, isA<ServerException>());
      final e = error! as ServerException;
      expect(e.statusCode, 404);
      expect(e.code, 'COMMON_404_NOT_FOUND');
      expect(e.message, '요청한 경로나 리소스를 찾을 수 없습니다.');
      expect(e.retryable, isFalse);
    });

    test('401은 인증 오류다', () async {
      final (:client, adapter: _) = _client(
        (_, _) async => _json({'success': false, 'code': 'AUTH_401'}, 401),
      );
      await expectLater(
        client.get('/x', decode: ignoreData),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.code,
            'code',
            'AUTH_401',
          ),
        ),
      );
    });

    test('JSON이 아닌 500 응답은 기본 메시지의 서버 오류다', () async {
      final (:client, adapter: _) = _client(
        (_, _) async => ResponseBody.fromString('Bad Gateway', 500),
      );
      await expectLater(
        client.post('/x', decode: ignoreData),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'status', 500)
              .having((e) => e.retryable, 'retryable', isTrue),
        ),
      );
    });

    for (final (type, matcher) in [
      (DioExceptionType.connectionError, isA<NetworkException>()),
      (DioExceptionType.connectionTimeout, isA<RequestTimeoutException>()),
      (DioExceptionType.receiveTimeout, isA<RequestTimeoutException>()),
      (DioExceptionType.cancel, isA<CancelledException>()),
    ]) {
      test('${type.name}는 공통 앱 오류로 바뀐다', () async {
        final (:client, adapter: _) = _client((o, _) async => _throw(o, type));
        await expectLater(
          client.post('/x', decode: ignoreData),
          throwsA(matcher),
        );
      });
    }
  });

  group('재시도', () {
    test('GET은 연결 실패 시 다시 보내 성공한다', () async {
      final (:client, :adapter) = _client(
        (o, call) async => call == 1
            ? _throw(o, DioExceptionType.connectionError)
            : _json(_envelope(7)),
      );
      expect(await client.get('/x', decode: (d) => d), 7);
      expect(adapter.requests, hasLength(2));
    });

    test('GET은 최대 2번까지만 다시 보낸다', () async {
      final (:client, :adapter) = _client(
        (o, _) async => _throw(o, DioExceptionType.connectionError),
      );
      await expectLater(
        client.get('/x', decode: ignoreData),
        throwsA(isA<NetworkException>()),
      );
      expect(adapter.requests, hasLength(3));
    });

    test('POST는 중복 전송을 막기 위해 다시 보내지 않는다', () async {
      final (:client, :adapter) = _client(
        (o, _) async => _throw(o, DioExceptionType.connectionError),
      );
      await expectLater(
        client.post('/x', decode: ignoreData),
        throwsA(isA<NetworkException>()),
      );
      expect(adapter.requests, hasLength(1));
    });
  });

  group('공통 헤더', () {
    test('기본 헤더와 타임아웃을 붙이고 토큰이 없으면 Authorization을 뺀다', () async {
      final (:client, :adapter) = _client((_, _) async => _json(_envelope(1)));
      await client.get('/x', decode: (d) => d);
      final o = adapter.requests.single;
      expect(o.headers['Accept'], 'application/json');
      expect(o.headers['Accept-Language'], 'ko-KR');
      expect(o.headers.containsKey('X-Client-Platform'), isFalse);
      expect(o.headers.containsKey('Authorization'), isFalse);
      expect(o.connectTimeout, _config.connectTimeout);
      expect(o.receiveTimeout, _config.receiveTimeout);
    });

    test('토큰이 있으면 Bearer로 보낸다', () async {
      final (:client, :adapter) = _client(
        (_, _) async => _json(_envelope(1)),
        token: 'abc',
      );
      await client.get('/x', decode: (d) => d);
      expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
    });

    test('음성 업로드는 multipart로 보낸다', () async {
      final (:client, :adapter) = _client((_, _) async => _json(_envelope(1)));
      await client.postForm(
        '/api/v1/searches',
        form: FormData.fromMap({
          'target': 'DESTINATION',
          'audio': MultipartFile.fromBytes([1, 2, 3], filename: 'q.m4a'),
        }),
        decode: (d) => d,
      );
      expect(
        adapter.requests.single.contentType,
        startsWith(Headers.multipartFormDataContentType),
      );
    });
  });
}
