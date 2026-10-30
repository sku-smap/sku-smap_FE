import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/core/network/api_client.dart';
import 'package:smap/core/network/app_config.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/campus_status_providers.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/navigation/data/api_route_repository.dart';
import 'package:smap/features/navigation/data/dto/route_dto.dart';
import 'package:smap/features/navigation/data/guide_voice.dart';
import 'package:smap/features/navigation/data/mock_route_repository.dart';
import 'package:smap/features/navigation/data/navigation_assets.dart';
import 'package:smap/features/navigation/data/navigation_models.dart';
import 'package:smap/features/navigation/data/route_graph.dart';
import 'package:smap/features/navigation/data/route_plan.dart';
import 'package:smap/features/navigation/data/route_repository.dart';
import 'package:smap/features/navigation/presentation/widgets/viewer_stage.dart';
import 'package:smap/features/navigation/state/navigation_controller.dart';

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

Map<String, Object?> _seg(
  String from,
  String to, [
  String? type = 'WALK',
  String? note,
]) => {
  'fromNodeId': from,
  'toNodeId': to,
  'moveType': type,
  'description': note,
};

Map<String, Object?> _node(String id, {String? imageUrl}) => {
  'nodeId': id,
  'building': '야외',
  'floorLabel': '',
  'title': '$id 제목',
  'imageUrl': imageUrl,
};

Map<String, Object?> _route(
  List<Map<String, Object?>> segments, [
  List<Map<String, Object?>> nodes = const [],
]) => {'nodes': nodes, 'segments': segments, 'totalSteps': segments.length};

// gate_front → parking_3way → new_door (server only) → road_yudam_3way
final _withNewSpot = _route(
  [
    _seg('gate_front', 'parking_3way'),
    _seg('parking_3way', 'new_door', 'DOOR', '새 출입구로 들어가요'),
    _seg('new_door', 'road_yudam_3way'),
  ],
  [
    _node('gate_front'),
    _node('new_door', imageUrl: 'https://cdn.test/new.jpg'),
  ],
);

RoutePlan? _plan(Object json, String from, String to) =>
    RouteDto.planFrom(json, from: from, to: to);

class _Routes implements RouteRepository {
  final asked = <String>[];
  Future<RoutePlan?> Function(String from, String to) answer = (from, to) =>
      Future.value(_plan(_withNewSpot, from, to));

  @override
  Future<RoutePlan?> find({
    required String from,
    required String to,
    required RouteOption option,
  }) {
    asked.add('$from>$to:${option.name}');
    return answer(from, to);
  }
}

class _Voice implements GuideVoice {
  final spoken = <String>[];

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async {}
}

NavigationEntry _entry({
  String from = 'gate_front',
  String to = 'road_yudam_3way',
  RouteMode mode = RouteMode.outdoor,
  bool indoor = false,
  RouteOption? option,
}) => (from: from, to: to, mode: mode, indoor: indoor, option: option);

void main() {
  tearDown(() {
    resetSpots();
    resetPlaces();
    resetLinks();
  });

  group('경로 응답 매핑', () {
    test('구간을 이어 단계와 이동 방식을 만들고 지점 사진을 읽는다', () {
      final plan = _plan(_withNewSpot, 'gate_front', 'road_yudam_3way')!;
      expect(plan.path, [
        'gate_front',
        'parking_3way',
        'new_door',
        'road_yudam_3way',
      ]);
      expect(plan.legs.map((l) => l.via), [Via.walk, Via.door, Via.walk]);
      expect(plan.legs[1].note, '새 출입구로 들어가요');
      expect(plan.legs.first.note, isNull);
      expect(plan.spots.last.imageUrl, 'https://cdn.test/new.jpg');
      expect(plan.links, hasLength(3));
    });

    test('여러 층 엘리베이터는 한 단계로 합치고 모르는 이동 방식은 걷기다', () {
      final plan = _plan(
        _route([
          _seg('a', 'lift1', 'WALK'),
          _seg('lift1', 'lift2', 'ELEVATOR'),
          _seg('lift2', 'lift3', 'ELEVATOR'),
          _seg('lift3', 'b', 'PASSAGE'),
        ]),
        'a',
        'b',
      )!;
      expect(plan.path, ['a', 'lift1', 'lift3', 'b']);
      expect(plan.legs.map((l) => l.via), [Via.walk, Via.elevator, Via.walk]);
      expect(plan.legs[1].to, 'lift3');
      expect(plan.links, hasLength(4), reason: 'every segment joins the graph');
    });

    test('합친 엘리베이터 단계는 첫 구간의 방향을 쓴다', () {
      final plan = _plan(
        _route([
          {..._seg('a', 'lift1'), 'arrowYawDeg': 30},
          {..._seg('lift1', 'lift2', 'ELEVATOR'), 'arrowYawDeg': 0},
          {..._seg('lift2', 'lift3', 'ELEVATOR'), 'arrowYawDeg': 270},
        ]),
        'a',
        'lift3',
      )!;
      expect(plan.legs.map((l) => l.yaw), [30, 0]);
    });

    test('구간이 없으면 길 없음, 출발과 도착이 같으면 한 지점이다', () {
      expect(_plan(_route([]), 'a', 'b'), isNull);
      expect(_plan(<String, Object?>{}, 'a', 'b'), isNull);
      expect(_plan(_route([]), 'a', 'a')!.path, ['a']);
    });

    test('끊기거나 다른 곳으로 가는 경로는 응답 오류다', () {
      expect(
        () => _plan(_route([_seg('a', 'b'), _seg('c', 'd')]), 'a', 'd'),
        throwsA(isA<ParseException>()),
      );
      expect(
        () => _plan(_route([_seg('a', 'b')]), 'a', 'z'),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('경로 API', () {
    ({ApiRouteRepository repo, _Adapter adapter}) api(
      Object body, [
      int status = 200,
    ]) {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
      final adapter = _Adapter(body, status);
      dio.httpClientAdapter = adapter;
      return (repo: ApiRouteRepository(ApiClient(dio)), adapter: adapter);
    }

    Map<String, Object?> fail(String code) => {
      'success': false,
      'code': code,
      'message': '실패',
      'data': null,
    };

    test('출발·도착 노드와 옵션을 POST로 보낸다', () async {
      final (:repo, :adapter) = api({
        'success': true,
        'code': 'OK',
        'message': '',
        'data': _withNewSpot,
      });
      final plan = await repo.find(
        from: 'gate_front',
        to: 'road_yudam_3way',
        option: RouteOption.indoorUndergroundFirst,
      );
      final o = adapter.requests.single;
      expect(o.method, 'POST');
      expect(o.uri.path, '/api/v1/routes');
      expect(o.data, {
        'fromNodeId': 'gate_front',
        'toNodeId': 'road_yudam_3way',
        'option': 'INDOOR_UNDERGROUND_FIRST',
      });
      expect(plan!.path, hasLength(4));
    });

    test('404는 길 없음, 그 밖의 오류는 공통 앱 오류다', () async {
      expect(
        await api(
          fail('ROUTE_404'),
          404,
        ).repo.find(from: 'a', to: 'b', option: RouteOption.outdoorFirst),
        isNull,
      );
      await expectLater(
        api(
          fail('COMMON_500'),
          500,
        ).repo.find(from: 'a', to: 'b', option: RouteOption.outdoorFirst),
        throwsA(isA<ServerException>()),
      );
    });

    test('USE_MOCK이 꺼지면 경로 API 구현을 주입받는다', () {
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
      expect(c.read(routeRepositoryProvider), isA<ApiRouteRepository>());
    });

    test('mock은 앱 경로 데이터로 찾고 단계마다 이동 방식을 채운다', () async {
      final plan = await MockRouteRepository(blocked: () => {}).find(
        from: 'gate_front',
        to: 'bukak_b1_elev',
        option: RouteOption.outdoorFirst,
      );
      expect(plan!.path, findRoute('gate_front', 'bukak_b1_elev'));
      expect(plan.legs, hasLength(plan.path.length - 1));
    });
  });

  group('경로 옵션', () {
    test('검색 옵션이 먼저, 그다음 실내 길, 그다음 이동 방식으로 하나만 보낸다', () {
      expect(routeOptionOf(_entry()), RouteOption.outdoorFirst);
      expect(
        routeOptionOf(_entry(mode: RouteMode.comfortable)),
        RouteOption.comfortable,
      );
      expect(
        routeOptionOf(_entry(mode: RouteMode.shortest)),
        RouteOption.shortest,
      );
      expect(
        routeOptionOf(_entry(mode: RouteMode.comfortable, indoor: true)),
        RouteOption.indoorUndergroundFirst,
        reason: 'the mode buttons hide while indoor is on',
      );
      expect(
        routeOptionOf(_entry(indoor: true, option: RouteOption.shortest)),
        RouteOption.shortest,
      );
    });

    test('실내 길을 직접 바꾸면 검색 옵션은 지운다', () {
      final c = ProviderContainer(
        overrides: [launchQueryProvider.overrideWithValue(const {})],
      );
      addTearDown(c.dispose);
      c.read(tripProvider.notifier)
        ..applyRouteOption(RouteOption.shortest)
        ..toggleIndoor();
      expect(c.read(tripProvider).routeOption, isNull);
      expect(c.read(tripProvider).indoor, isTrue);
    });
  });

  group('길안내 상태', () {
    late _Routes routes;
    late _Voice voice;
    late List<List<String>> prefetched;

    Future<ProviderContainer> start(
      NavigationEntry entry, {
      List<Closure> closures = const [],
    }) async {
      routes = _Routes();
      voice = _Voice();
      prefetched = [];
      final c = ProviderContainer(
        overrides: [
          launchQueryProvider.overrideWithValue(const {}),
          routeRepositoryProvider.overrideWithValue(routes),
          photoPrefetchProvider.overrideWithValue(prefetched.add),
          guideVoiceProvider.overrideWithValue(voice),
          campusClosuresProvider.overrideWith((_) async => closures),
        ],
      );
      addTearDown(c.dispose);
      c.listen(navigationProvider(entry), (_, _) {});
      await pumpEventQueue();
      return c;
    }

    test('서버 경로로 단계·사진·화살표·안내 문장을 만든다', () async {
      final entry = _entry(mode: RouteMode.comfortable);
      final c = await start(entry);
      final s = c.read(navigationProvider(entry));

      expect(routes.asked, ['gate_front>road_yudam_3way:comfortable']);
      expect(s.route!.path, hasLength(4));
      expect(s.node, 'gate_front');
      expect(voice.spoken.single, s.text);

      c.read(navigationProvider(entry).notifier).goTo('parking_3way');
      final next = c.read(navigationProvider(entry));
      expect(next.text, '출입구를 지나 new_door 제목(으)로 들어가세요');
      expect(spotById['new_door']!.imageUrl, 'https://cdn.test/new.jpg');
      final arrow = viewLinks(
        'parking_3way',
        next.next,
      ).firstWhere((l) => l.primary);
      expect(arrow.to, 'new_door');
      expect(arrow.chip, isTrue, reason: 'no photo direction from the server');
    });

    test('경로를 받으면 다음 단계부터 도착까지 사진을 순서대로 미리 받는다', () async {
      final entry = _entry();
      final c = await start(entry);
      expect(prefetched.single, [
        NavigationAssets.pano('parking_3way'),
        'https://cdn.test/new.jpg',
        NavigationAssets.pano('road_yudam_3way'),
      ]);

      c.read(navigationProvider(entry).notifier).goTo('parking_3way');
      expect(prefetched.last, [
        'https://cdn.test/new.jpg',
        NavigationAssets.pano('road_yudam_3way'),
      ]);
    });

    test('길이 없으면 알리고, 모르는 지점이 섞이면 오류다', () async {
      final entry = _entry();
      final c = await start(entry);
      routes.answer = (_, _) async => null;
      c.invalidate(navigationProvider(entry));
      await pumpEventQueue();
      expect(c.read(navigationProvider(entry)).route, isNull);
      expect(
        c.read(navigationProvider(entry)).toast,
        NavigationController.noRoute,
      );

      routes.answer = (from, to) async => RoutePlan(
        path: [from, 'ghost', to],
        legs: const [
          RouteLink(to: 'ghost', via: Via.walk),
          RouteLink(to: 'road_yudam_3way', via: Via.walk),
        ],
      );
      c.invalidate(navigationProvider(entry));
      await pumpEventQueue();
      expect(c.read(navigationProvider(entry)).error, isNotNull);
    });

    test('합친 엘리베이터 구간은 사진 연결로 넣지 않는다', () async {
      final entry = _entry();
      final c = await start(entry);
      routes.answer = (from, to) async => _plan(
        _route([
          _seg(from, 'parking_3way'),
          _seg('parking_3way', to, 'ELEVATOR'),
        ]),
        from,
        to,
      );
      c.invalidate(navigationProvider(entry));
      await pumpEventQueue();
      expect(c.read(navigationProvider(entry)).route, isNotNull);
      expect(
        linksOf('parking_3way')
            .where((l) => l.to == 'road_yudam_3way' && l.via == Via.elevator),
        isEmpty,
      );
    });

    test('조회가 실패하면 오류를 보여주고 다시 시도한다', () async {
      final entry = _entry();
      final c = await start(entry);
      routes.answer = (_, _) => Future.error(const NetworkException());
      c.invalidate(navigationProvider(entry));
      await pumpEventQueue();
      expect(c.read(navigationProvider(entry)).error, '인터넷 연결을 확인해 주세요.');

      routes.answer = (from, to) async => _plan(_withNewSpot, from, to);
      c.read(navigationProvider(entry).notifier).retry();
      expect(c.read(navigationProvider(entry)).loading, isTrue);
      await pumpEventQueue();
      expect(c.read(navigationProvider(entry)).error, isNull);
      expect(c.read(navigationProvider(entry)).route, isNotNull);
    });

    test('못 가는 곳을 지나는 서버 경로는 경고한다', () async {
      final entry = _entry();
      final c = await start(
        entry,
        closures: const [Closure(node: 'parking_3way', place: '주차장')],
      );
      expect(
        c.read(navigationProvider(entry)).toast,
        NavigationController.closedOnRoute,
      );
    });

    test('엘리베이터 우선인데 계단이 섞이면 알려준다', () async {
      final entry = _entry(mode: RouteMode.comfortable);
      final c = await start(entry);
      routes.answer = (from, to) async => _plan(
        _route([
          _seg(from, 'parking_3way', 'STAIRS'),
          _seg('parking_3way', to),
        ]),
        from,
        to,
      );
      c.invalidate(navigationProvider(entry));
      await pumpEventQueue();
      expect(
        c.read(navigationProvider(entry)).toast,
        '엘리베이터로만 가는 길이 없어서 계단이 조금 포함돼요',
      );
    });

    test('경로 밖으로 가면 그 지점에서 다시 찾고, 늦은 응답은 버린다', () async {
      final entry = _entry();
      final c = await start(entry);
      final nav = c.read(navigationProvider(entry).notifier);

      final late = Completer<RoutePlan?>();
      routes.answer = (_, _) => late.future;
      nav.goTo('road_hanlim_3way');
      expect(
        routes.asked.last,
        'road_hanlim_3way>road_yudam_3way:outdoorFirst',
      );
      nav.goTo('gate_front');
      late.complete(
        RoutePlan(
          path: const ['road_hanlim_3way', 'road_yudam_3way'],
          legs: const [RouteLink(to: 'road_yudam_3way', via: Via.walk)],
        ),
      );
      await pumpEventQueue();
      expect(c.read(navigationProvider(entry)).route!.from.id, 'gate_front');

      routes.answer = (from, to) async => RoutePlan(
        path: [from, to],
        legs: [RouteLink(to: to, via: Via.walk)],
      );
      nav.goTo('road_hanlim_3way');
      await pumpEventQueue();
      final s = c.read(navigationProvider(entry));
      expect(s.route!.path, ['road_hanlim_3way', 'road_yudam_3way']);
      expect(s.stepIdx, 0);
      expect(s.toast, '경로를 다시 찾았어요');
    });
  });
}
