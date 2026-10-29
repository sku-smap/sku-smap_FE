import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/api_client.dart';
import 'package:smap/core/network/app_config.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/api_campus_map_repository.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_map.dart';
import 'package:smap/features/campus/data/campus_map_repository.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/dto/campus_map_dto.dart';
import 'package:smap/features/campus/state/node_providers.dart';
import 'package:smap/features/navigation/data/navigation_models.dart';
import 'package:smap/features/navigation/data/route_graph.dart';
import 'package:smap/features/navigation/presentation/widgets/viewer_stage.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);

  final Object body;
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
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _node(
  String id, {
  String? imageUrl,
  List<Map<String, Object?>> places = const [],
}) => {
  'nodeId': id,
  'building': '야외',
  'floorLabel': '',
  'title': '$id 제목',
  'originalFilename': '$id.jpg',
  'imageUrl': imageUrl,
  'places': places,
};

Map<String, Object?> _edge(String from, String to, [String? type = 'WALK']) => {
  'fromNodeId': from,
  'toNodeId': to,
  'moveType': type,
  'description': '$from → $to',
};

final _map = {
  'nodes': [
    _node('gate_front', imageUrl: 'https://cdn.test/gate.jpg'),
    _node(
      'EJ1_02_E',
      imageUrl: ' ',
      places: [
        {
          'placeId': 'r-ej-201',
          'name': '은주1관 201호',
          'arriveNodeId': 'EJ1_02_E',
          'kind': null,
          'aliases': ['201호', '은주1관 201'],
        },
      ],
    ),
    {'nodeId': null, 'title': '버려질 지점'},
  ],
  'edges': [
    _edge('gate_front', 'EJ1_02_E', 'DOOR'),
    _edge('EJ1_02_E', 'gate_front', 'LIFT'),
    _edge('EJ1_02_E', 'missing_node'),
    {'fromNodeId': null, 'toNodeId': 'gate_front'},
  ],
  'totalNodes': 2,
  'totalEdges': 2,
  'totalPlaces': 1,
};

class _Stub implements CampusMapRepository {
  _Stub(this.map);

  CampusMap map;
  var loads = 0;

  @override
  Future<CampusMap> load() async {
    loads++;
    return map;
  }
}

void main() {
  tearDown(() {
    resetSpots();
    resetPlaces();
    resetLinks();
  });

  group('지도 DTO 매핑', () {
    test('지점·사진 URL·지점별 장소·연결을 앱 데이터로 바꾼다', () {
      final map = CampusMapDto.fromJson(_map);

      expect(map.spots.map((s) => s.id), ['gate_front', 'EJ1_02_E']);
      expect(map.spots.first.imageUrl, 'https://cdn.test/gate.jpg');
      expect(map.spots.last.imageUrl, isNull);
      expect(map.places.single.id, 'r-ej-201');
      expect(map.places.single.node, 'EJ1_02_E');
      expect(map.places.single.aliases, ['201호', '은주1관 201']);
    });

    test('양쪽 지점이 응답에 있는 연결만 남기고 이동 방식을 바꾼다', () {
      final links = CampusMapDto.fromJson(_map).links;

      expect(links, hasLength(2));
      final (from, door) = links.first;
      expect(from, 'gate_front');
      expect(door.to, 'EJ1_02_E');
      expect(door.via, Via.door);
      expect(door.note, 'gate_front → EJ1_02_E');
      expect(door.fromServer, isTrue);
      expect(links.last.$2.via, Via.walk, reason: 'unknown move type walks');
    });

    test('nodes·edges가 없어도 빈 지도로 읽는다', () {
      expect(CampusMapDto.fromJson(<String, Object?>{}).isEmpty, isTrue);
    });
  });

  group('지도 API', () {
    test('캠퍼스 지도를 조회한다', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _Adapter({
        'success': true,
        'code': 'OK',
        'message': '',
        'data': _map,
      });
      dio.httpClientAdapter = adapter;
      final map = await ApiCampusMapRepository(ApiClient(dio)).load();
      expect(map.spots, hasLength(2));
      expect(adapter.requests.single.uri.path, '/api/v1/campus-map');
    });

    test('USE_MOCK이 꺼지면 지도 API 구현을 주입받는다', () {
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
      expect(
        c.read(campusMapRepositoryProvider),
        isA<ApiCampusMapRepository>(),
      );
    });
  });

  group('지도 데이터 반영', () {
    ProviderContainer container(CampusMap map) {
      final c = ProviderContainer(
        overrides: [campusMapRepositoryProvider.overrideWithValue(_Stub(map))],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('한 번 받아 지점·연결·장소를 함께 반영한다', () async {
      final c = container(CampusMapDto.fromJson(_map));
      final spots = await c.read(nodeCatalogProvider.future);

      expect(spots, hasLength(2));
      expect(spotById['gate_front']!.imageUrl, 'https://cdn.test/gate.jpg');
      expect(spotById['gate_front']!.onMap, isTrue);
      expect(nodeOf('r-ej-201'), 'EJ1_02_E');
      expect(linksOf('EJ1_02_E').map((l) => l.to), contains('gate_front'));
      expect(findRoute('road_yudam_3way', 'EJ1_02_E'), isNotNull);
    });

    test('이미 있는 연결은 앱 데이터를 유지하고 없는 연결만 더한다', () async {
      final before = linksOf('gate_front').length;
      final c = container(
        CampusMap(
          spots: CampusMapDto.fromJson(_map).spots,
          links: [
            (
              'gate_front',
              const RouteLink(
                to: 'parking_3way',
                via: Via.stairs,
                fromServer: true,
              ),
            ),
            (
              'gate_front',
              const RouteLink(to: 'EJ1_02_E', via: Via.walk, fromServer: true),
            ),
          ],
          places: const [],
        ),
      );
      await c.read(campusMapProvider.future);

      final links = linksOf('gate_front');
      expect(links, hasLength(before + 1));
      expect(links.where((l) => l.to == 'parking_3way').single.via, Via.walk);
    });

    test('지도를 다시 받아 사진 URL·장소를 바꾸고 화면 상태는 그대로 둔다', () async {
      final stub = _Stub(CampusMapDto.fromJson(_map));
      final c = ProviderContainer(
        overrides: [campusMapRepositoryProvider.overrideWithValue(stub)],
      );
      addTearDown(c.dispose);
      final first = await c.read(campusMapProvider.future);

      stub.map = CampusMap(
        spots: [spotById['gate_front']!.withPhoto('https://cdn.test/new.jpg')],
        links: const [],
        places: const [
          SearchPlace(
            id: 'r-new-1',
            name: '새 장소',
            kind: PlaceKind.room,
            node: 'gate_front',
          ),
        ],
      );
      await c.read(campusMapRefreshProvider)();
      expect(spotById['gate_front']!.imageUrl, 'https://cdn.test/new.jpg');
      expect(nodeOf('r-new-1'), 'gate_front');
      expect(c.read(campusMapProvider).value, same(first));
    });

    testWidgets('API 모드에서는 4분 30초마다 화면 뒤에서 다시 받는다', (tester) async {
      final stub = _Stub(CampusMapDto.fromJson(_map));
      final c = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              env: AppEnv.dev,
              baseUrl: 'https://x',
              useMock: false,
            ),
          ),
          campusMapRepositoryProvider.overrideWithValue(stub),
        ],
      );
      c.listen(campusMapProvider, (_, _) {});
      await tester.pump();
      expect(stub.loads, 1);

      await tester.pump(campusMapRefresh);
      await tester.pump(campusMapRefresh);
      expect(stub.loads, 3);
      expect(c.read(campusMapProvider).hasValue, isTrue);
      c.dispose();
    });

    test('빈 지도는 오류로 보고 재시도할 수 있다', () async {
      final c = container(const CampusMap(spots: [], links: [], places: []));
      await expectLater(
        c.read(campusMapProvider.future),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            '지도 데이터가 비어 있어요.',
          ),
        ),
      );
    });

    test('방향을 모르는 서버 연결은 칩으로, 보정값이 생기면 화살표로 보여준다', () async {
      final c = container(CampusMapDto.fromJson(_map));
      await c.read(campusMapProvider.future);

      final link = viewLinks(
        'gate_front',
        null,
      ).firstWhere((l) => l.to == 'EJ1_02_E');
      expect(link.chip, isTrue);
      final fixed = viewLinks('gate_front', null, {
        'gate_front>EJ1_02_E': 90,
      }).firstWhere((l) => l.to == 'EJ1_02_E');
      expect(fixed.chip, isFalse);
      expect(fixed.yaw, 90);
      expect(
        viewLinks(
          'gate_front',
          null,
        ).where((l) => l.to != 'EJ1_02_E').every((l) => !l.chip),
        isTrue,
        reason: 'bundled links keep their arrows',
      );
    });
  });
}
