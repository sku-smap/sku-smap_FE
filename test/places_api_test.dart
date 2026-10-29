import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/api_client.dart';
import 'package:smap/core/network/app_config.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/api_place_repository.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/dto/place_dto.dart';
import 'package:smap/features/campus/data/mock/mock_place_repository.dart';
import 'package:smap/features/campus/data/place_repository.dart';
import 'package:smap/features/campus/state/place_providers.dart';
import 'package:smap/features/navigation/data/route_graph.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body, [this.status = 200]);

  final Object body;
  final int status;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _place({
  String? placeId = 'r-test-101',
  String? name = '테스트실 (101호)',
  String? kind = 'room',
  String? arriveNodeId = 'gate_front',
  Object? aliases = const <String>[],
  String? sub,
  String? building = '유담관',
  String? floorLabel = '1층',
  String? roomNo = '101',
}) => {
  'placeId': placeId,
  'name': name,
  'kind': kind,
  'building': building,
  'floorLabel': floorLabel,
  'roomNo': roomNo,
  'arriveNodeId': arriveNodeId,
  'arriveNodeTitle': '정문 앞',
  'doorPhoto': null,
  'aliases': aliases,
  'sub': sub,
};

({ApiPlaceRepository repo, _Adapter adapter}) _api(
  Object body, [
  int status = 200,
]) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  final adapter = _Adapter(body, status);
  dio.httpClientAdapter = adapter;
  return (repo: ApiPlaceRepository(ApiClient(dio)), adapter: adapter);
}

Map<String, Object?> _ok(Object? data) => {
  'success': true,
  'code': 'COMMON_200_OK',
  'message': '성공',
  'data': data,
};

class _StubRepository implements PlaceRepository {
  const _StubRepository(this.places);

  final List<SearchPlace> places;

  @override
  Future<List<SearchPlace>> all() async => places;

  @override
  Future<List<SearchPlace>> search(String keyword) async => places;
}

void main() {
  tearDown(resetPlaces);

  group('장소 DTO 매핑', () {
    test('서버 필드를 앱 장소로 바꾼다', () {
      final p = PlaceDto.fromJson(
        _place(aliases: ['테스트', ' 실습실 ', '', '테스트'], sub: '유담관 1층'),
      ).toModel()!;
      expect(p.id, 'r-test-101');
      expect(p.name, '테스트실 (101호)');
      expect(p.kind, PlaceKind.room);
      expect(p.node, 'gate_front');
      expect(p.sub, '유담관 1층');
      expect(p.aliases, ['테스트', '실습실']);
    });

    test('예전 문자열 별명은 | 나 , 로 나누고 없으면 빈 목록이다', () {
      expect(
        PlaceDto.fromJson(_place(aliases: '학식|밥집, 식당')).toModel()!.aliases,
        ['학식', '밥집', '식당'],
      );
      expect(PlaceDto.fromJson(_place(aliases: null)).toModel()!.aliases, []);
    });

    test('sub가 없으면 건물·층·호수로 채운다', () {
      expect(PlaceDto.fromJson(_place()).toModel()!.sub, '유담관 1층 101호');
      expect(
        PlaceDto.fromJson(_place(roomNo: null, floorLabel: 'B1층'))
            .toModel()!
            .sub,
        '유담관 B1',
      );
      expect(
        PlaceDto.fromJson(_place(floorLabel: '2', roomNo: '202호'))
            .toModel()!
            .sub,
        '유담관 2층 202호',
      );
      expect(
        PlaceDto.fromJson(
          _place(building: null, floorLabel: null, roomNo: null),
        ).toModel()!.sub,
        isNull,
      );
    });

    test('kind가 없거나 모르는 값이면 시설로 본다', () {
      expect(
        PlaceDto.fromJson(_place(kind: null)).toModel()!.kind,
        PlaceKind.facility,
      );
      expect(
        PlaceDto.fromJson(_place(kind: 'lab')).toModel()!.kind,
        PlaceKind.facility,
      );
      for (final k in PlaceKind.values) {
        expect(PlaceDto.fromJson(_place(kind: k.name)).toModel()!.kind, k);
      }
    });

    test('ID·이름·도착 지점 중 하나라도 없으면 버린다', () {
      expect(PlaceDto.fromJson(_place(placeId: null)).toModel(), isNull);
      expect(PlaceDto.fromJson(_place(name: '  ')).toModel(), isNull);
      expect(PlaceDto.fromJson(_place(arriveNodeId: '')).toModel(), isNull);
    });
  });

  group('장소 API', () {
    test('검색어 없이 전체 장소를 조회한다', () async {
      final (:repo, :adapter) = _api(_ok([_place(), _place(placeId: null)]));
      final places = await repo.all();
      expect(places.map((p) => p.id), ['r-test-101']);
      final uri = adapter.requests.single.uri;
      expect(uri.path, '/api/v1/places');
      expect(uri.queryParameters, isEmpty);
    });

    test('키워드로 검색한다', () async {
      final (:repo, :adapter) = _api(_ok([_place()]));
      await repo.search('도시공학과 실습실');
      expect(adapter.requests.single.uri.queryParameters, {
        'keyword': '도시공학과 실습실',
      });
    });

    test('오류 응답은 공통 앱 오류로 바뀐다', () async {
      final (:repo, adapter: _) = _api({
        'success': false,
        'code': 'COMMON_500',
        'message': '서버 오류',
        'data': null,
      }, 500);
      await expectLater(repo.search('본관'), throwsA(isA<ServerException>()));
    });

    test('data가 목록이 아니면 파싱 오류다', () async {
      final (:repo, adapter: _) = _api(_ok({'placeId': 'x'}));
      await expectLater(repo.all(), throwsA(isA<ParseException>()));
    });
  });

  group('장소 ID와 촬영 지점', () {
    test('서버에만 있는 장소도 전체 조회 뒤 ID로 찾고 길을 찾는다', () async {
      const server = SearchPlace(
        id: 'r-server-1',
        name: '서버 실습실',
        kind: PlaceKind.room,
        node: 'road_yudam_3way',
      );
      expect(resolvePlace(server.id), isNull);

      final c = ProviderContainer(
        overrides: [
          placeRepositoryProvider.overrideWithValue(
            const _StubRepository([server]),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(placeCatalogProvider.future);

      expect(resolvePlace(server.id)?.name, '서버 실습실');
      expect(nodeOf(server.id), 'road_yudam_3way');
      expect(routeEndFor(server.id)?.node, 'road_yudam_3way');
    });

    test('자주 찾는 곳은 전체 목록에서 정해진 순서로 고른다', () async {
      final c = ProviderContainer(
        overrides: [
          placeRepositoryProvider.overrideWithValue(
            const MockPlaceRepository(),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(placeCatalogProvider.future);
      final ids = c.read(popularPlacesProvider).value!.map((p) => p.id);
      expect(ids, popularPlaceIds);
    });

    test('서버 목록에 없는 자주 찾는 곳은 빠진다', () async {
      final c = ProviderContainer(
        overrides: [
          placeRepositoryProvider.overrideWithValue(
            const _StubRepository([
              SearchPlace(
                id: 'b-bonkwan',
                name: '본관',
                kind: PlaceKind.building,
                node: 'bon_1f_front',
              ),
            ]),
          ),
        ],
      );
      addTearDown(c.dispose);
      await c.read(placeCatalogProvider.future);
      expect(c.read(popularPlacesProvider).value!.map((p) => p.id), [
        'b-bonkwan',
      ]);
    });

    test('USE_MOCK이 꺼지면 장소 API 구현을 주입받는다', () {
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              env: AppEnv.dev,
              baseUrl: 'https://x',
              useMock: false,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(placeRepositoryProvider), isA<ApiPlaceRepository>());
    });
  });
}
