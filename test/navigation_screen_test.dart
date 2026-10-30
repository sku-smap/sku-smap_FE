import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/features/navigation/data/guide_voice.dart';
import 'package:smap/features/navigation/data/mock_route_repository.dart';
import 'package:smap/features/navigation/data/route_plan.dart';
import 'package:smap/features/navigation/data/route_repository.dart';
import 'package:smap/features/navigation/data/route_graph.dart';
import 'package:smap/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:smap/features/navigation/state/navigation_controller.dart';

final _pixel = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

class _FakeVoice implements GuideVoice {
  final spoken = <String>[];
  var stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}

GoRouter _router(String initial) {
  Widget page(GoRouterState state) => Scaffold(body: Text('page ${state.uri}'));
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home')),
        routes: [
          GoRoute(
            path: 'navigation',
            builder: (_, state) =>
                NavigationScreen(query: state.uri.queryParameters),
          ),
          GoRoute(path: 'report', builder: (_, state) => page(state)),
        ],
      ),
    ],
  );
}

// Fails until the test lets it through, then walks the bundled graph
class _FlakyRoutes implements RouteRepository {
  var fail = true;

  @override
  Future<RoutePlan?> find({
    required String from,
    required String to,
    required RouteOption option,
  }) => fail
      ? Future.error(const NetworkException())
      : MockRouteRepository(blocked: () => {})
            .find(from: from, to: to, option: option);
}

Future<_FakeVoice> _pump(
  WidgetTester tester,
  String initial, {
  RouteRepository? routes,
  List<String>? photos,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final voice = _FakeVoice();
  final router = _router(initial);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        guideVoiceProvider.overrideWithValue(voice),
        photoImageProvider.overrideWithValue((url) {
          photos?.add(url);
          return _pixel;
        }),
        photoPrefetchProvider.overrideWithValue((_) {}),
        if (routes != null) routeRepositoryProvider.overrideWithValue(routes),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  // Catalogs, then the route request
  await tester.pump();
  await tester.pump();
  return voice;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

const _toGs25 = '/navigation?from=f-gate&to=r-bukak-954&mode=outdoor';

void main() {
  group('경로 규칙', () {
    test('정문에서 GS25까지 8단계로 안내한다 (N-01~N-10)', () {
      final path = findRoute('gate_front', 'bukak_b1_elev')!;
      expect(path.length - 1, 8);
      expect(instruction(path[0], path[1]), '정문 앞 3갈래 교차로 방향으로 이동하세요');
      expect(spotById[path[6]]!.title, '서경대학교');
    });

    test('막힌 지점은 피해서 간다 (N-16)', () {
      final open = findRoute('gate_front', 'bon_1f_front')!;
      expect(open, contains('road_bon_2way'));
      final detour = findRoute(
        'gate_front',
        'bon_1f_front',
        blocked: {'road_bon_2way'},
      );
      expect(detour, isNot(contains('road_bon_2way')));
    });

    test('엘리베이터 우선이면 계단을 피한다 (N-15)', () {
      final walk = findRoute('bus_stop', 'bukak_b1_elev')!;
      final lift = findRoute(
        'bus_stop',
        'bukak_b1_elev',
        mode: RouteMode.comfortable,
      )!;
      expect(usesStairs(lift), isFalse);
      expect(walk, isNotEmpty);
    });
  });

  testWidgets('1단계 카드와 음성 안내를 보여준다 (N-01)', (tester) async {
    final voice = await _pump(tester, _toGs25);
    await tester.pump();

    expect(find.text('1 / 8단계'), findsOneWidget);
    expect(find.text('→ GS25 편의점'), findsOneWidget);
    expect(find.text('정문 앞 3갈래 교차로 방향으로 이동하세요'), findsOneWidget);
    expect(find.text('정문 앞'), findsOneWidget);
    expect(find.text('지상'), findsOneWidget);
    expect(voice.spoken.last, '정문 앞 3갈래 교차로 방향으로 이동하세요');
  });

  testWidgets('다음·이전으로 단계를 오간다 (N-04·N-14)', (tester) async {
    final voice = await _pump(tester, _toGs25);

    await _tap(tester, find.text('다음'));
    expect(find.text('2 / 8단계'), findsOneWidget);
    expect(voice.spoken.last, '유담관 3갈래 교차로 방향으로 이동하세요');

    await _tap(tester, find.text('이전'));
    expect(find.text('1 / 8단계'), findsOneWidget);
  });

  testWidgets('미니맵을 끄고 켠다 (N-02)', (tester) async {
    await _pump(tester, _toGs25);

    expect(find.text('지상'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('미니맵'));
    expect(find.text('지상'), findsNothing);
    await _tap(tester, find.bySemanticsLabel('미니맵'));
    expect(find.text('지상'), findsOneWidget);
  });

  testWidgets('음성 안내를 끄면 다음 단계를 읽지 않는다 (N-03)', (tester) async {
    final voice = await _pump(tester, _toGs25);
    await tester.pump();

    await _tap(tester, find.bySemanticsLabel('음성 안내 끄기'));
    expect(find.bySemanticsLabel('음성 안내 켜기'), findsOneWidget);
    expect(voice.stops, greaterThan(0));

    final before = voice.spoken.length;
    await _tap(tester, find.text('다음'));
    expect(voice.spoken.length, before);
  });

  testWidgets('전체 경로에 단계 수와 단계 목록을 보여주고 시간은 없다 (N-11)', (tester) async {
    await _pump(tester, _toGs25);

    await _tap(tester, find.bySemanticsLabel('전체 단계 보기'));
    expect(find.text('단계별 안내 · 8단계'), findsOneWidget);
    expect(find.text('출발'), findsOneWidget);
    expect(find.text('도착'), findsOneWidget);
    expect(find.textContaining('도보'), findsOneWidget);
    expect(find.textContaining('(예상)'), findsNothing);
    expect(find.textContaining('분'), findsNothing);

    await _tap(tester, find.bySemanticsLabel('닫기'));
    expect(find.text('단계별 안내 · 8단계'), findsNothing);
  });

  testWidgets('도착하면 평가하고 안내를 끝낸다 (N-12·N-13)', (tester) async {
    await _pump(tester, '/');
    GoRouter.of(tester.element(find.text('home'))).push(_toGs25);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (var i = 0; i < 8; i++) {
      await _tap(tester, find.text('다음'));
    }
    expect(find.text('도착'), findsOneWidget);
    expect(find.text('GS25 편의점에 도착했어요'), findsOneWidget);

    await _tap(tester, find.text('👍 정확했어요'));
    expect(find.text('고마워요! 👍'), findsOneWidget);

    await _tap(tester, find.text('안내 종료'));
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('건물 안에서는 층 버튼과 층 안내도를 보여준다', (tester) async {
    await _pump(tester, '/navigation?from=b-bukak&to=r-bukak-954');

    expect(find.text('북악관 1F'), findsOneWidget);
    expect(find.bySemanticsLabel('B1로 이동'), findsOneWidget);

    await _tap(tester, find.bySemanticsLabel('1층 층 안내도 열기'));
    expect(find.text('북악관 1층'), findsOneWidget);
  });

  testWidgets('못 가는 곳 데모를 켜면 그 지점을 피한다 (N-16)', (tester) async {
    await _pump(
      tester,
      '/navigation?from=f-gate&to=b-bonkwan&mode=outdoor&closures=demo',
    );

    for (var i = 0; i < 25 && find.text('도착').evaluate().isEmpty; i++) {
      expect(find.text('본관 오르막 2갈래'), findsNothing);
      await _tap(tester, find.text('다음'));
    }
    expect(find.text('도착'), findsOneWidget);
  });

  testWidgets('길 데이터가 없으면 알려주고 돌아갈 수 있다', (tester) async {
    await _pump(tester, '/navigation?from=f-bus&to=b-hyein');

    expect(find.text('아직 연결된 길 데이터가 없어요'), findsOneWidget);
    expect(find.text('돌아가기'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('제보 깃발은 지점과 단계를 담아 제보로 간다', (tester) async {
    await _pump(tester, _toGs25);

    await _tap(tester, find.bySemanticsLabel('제보하기 (헷갈려요·못 가요)'));
    expect(find.text('page /report?node=gate_front&step=0'), findsOneWidget);
  });

  testWidgets('링크에 출발·도착이 없으면 전역 출발·도착과 옵션으로 안내한다', (tester) async {
    await _pump(tester, '/');
    final home = tester.element(find.text('home'));
    ProviderScope.containerOf(home).read(tripProvider.notifier)
      ..setFrom(const CampusPlace(id: 'f-gate', name: '정문'))
      ..setTo(const CampusPlace(id: 'r-bukak-954', name: 'GS25 편의점'));
    GoRouter.of(home).push('/navigation');
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('1 / 8단계'), findsOneWidget);
    expect(find.text('→ GS25 편의점'), findsOneWidget);
  });

  testWidgets('잘못된 장소 ID로 열면 돌아갈 수 있다', (tester) async {
    await _pump(tester, '/navigation?from=nope&to=b-bonkwan&mode=fly');

    expect(find.text('아직 연결된 길 데이터가 없어요'), findsOneWidget);
    await _tap(tester, find.text('돌아가기'));
    expect(find.text('home'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('경로를 못 불러오면 다시 시도하고 돌아갈 수 있다', (tester) async {
    final routes = _FlakyRoutes();
    await _pump(tester, _toGs25, routes: routes);

    expect(find.text('인터넷 연결을 확인해 주세요. 눌러서 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('돌아가기'), findsOneWidget);

    routes.fail = false;
    await tester.tap(find.textContaining('다시 시도'));
    await tester.pump();
    await tester.pump();
    expect(find.text('1 / 8단계'), findsOneWidget);
  });

  testWidgets('단계 목록은 서버 썸네일, 없으면 원본 사진을 쓴다', (tester) async {
    final photos = <String>[];
    await _pump(tester, _toGs25, photos: photos);
    registerSpots([
      spotById['gate_front']!.withPhoto(
        'https://cdn.test/gate.jpg',
        thumb: 'https://cdn.test/gate_t.jpg',
      ),
      spotById['parking_3way']!.withPhoto('https://cdn.test/parking.jpg'),
    ]);
    addTearDown(resetSpots);

    await _tap(tester, find.bySemanticsLabel('전체 단계 보기'));
    expect(photos, contains('https://cdn.test/gate_t.jpg'));
    expect(photos, contains('https://cdn.test/parking.jpg'));
  });
}
