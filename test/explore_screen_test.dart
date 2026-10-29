import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_map.dart';
import 'package:smap/features/campus/data/campus_map_repository.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/mock/pano_spots_mock.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/node_providers.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/explore/presentation/screens/explore_screen.dart';
import 'package:smap/features/navigation/data/navigation_models.dart';
import 'package:smap/features/navigation/data/route_graph.dart';
import 'package:smap/features/navigation/state/navigation_controller.dart';

final _pixel = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

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
            path: 'explore',
            builder: (_, state) =>
                ExploreScreen(query: state.uri.queryParameters),
          ),
          GoRoute(path: 'search', builder: (_, state) => page(state)),
          GoRoute(path: 'report', builder: (_, state) => page(state)),
        ],
      ),
    ],
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  String initial, {
  Map<String, String> launch = const {},
  ImageProvider Function(String url)? photo,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router(initial);
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      launchQueryProvider.overrideWithValue(launch),
      photoImageProvider.overrideWithValue(photo ?? (_) => _pixel),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _settleToast(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('출발지가 없으면 정문에서 둘러본다 (E-01·E-02)', (tester) async {
    await _pump(tester, '/explore');

    expect(find.text('정문에서 둘러봐요. 출발지를 정하면 그 자리에서 열려요'), findsOneWidget);
    expect(find.text('거리뷰 둘러보기 · 사진 속 화살표로 이동'), findsOneWidget);
    expect(find.text('정문 앞'), findsNWidgets(2));
    expect(find.text('여기서 출발'), findsOneWidget);
    await _settleToast(tester);
    expect(find.textContaining('정문에서 둘러봐요'), findsNothing);
  });

  testWidgets('사진 속 화살표로 다음 지점에 간다 (E-03)', (tester) async {
    await _pump(tester, '/explore');

    await _tap(tester, find.bySemanticsLabel('정문 앞 3갈래 교차로'));
    expect(find.text('정문 앞 3갈래 교차로'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('미니맵을 끄고 켠다 (E-04)', (tester) async {
    await _pump(tester, '/explore');

    expect(find.text('지상'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('미니맵'));
    expect(find.text('지상'), findsNothing);
    await _tap(tester, find.bySemanticsLabel('미니맵'));
    expect(find.text('지상'), findsOneWidget);
    await _settleToast(tester);
  });

  testWidgets('여기서 출발하면 출발지로 정하고 도착지를 고른다 (E-05)', (tester) async {
    final container = await _pump(tester, '/explore');

    await _tap(tester, find.text('여기서 출발'));
    expect(find.text('page /search?pick=to'), findsOneWidget);
    final from = container.read(tripProvider).from;
    expect(from?.id, 'gate_front');
    expect(from?.name, '정문 앞');
    await _settleToast(tester);
  });

  testWidgets('NFC 출발지가 있으면 그 자리에서 연다 (E-06)', (tester) async {
    await _pump(tester, '/explore', launch: {'from': 'bus_stop'});

    expect(find.text('지금 위치(버스정류장)에서 둘러봐요. 사진 속 화살표로 이동하세요'), findsOneWidget);
    expect(find.text('서경대학교'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('건물 시트의 층 거리뷰는 그 층에서 연다 (E-07)', (tester) async {
    await _pump(tester, '/explore?building=bukak&floor=B1');

    expect(find.text('북악관 지하1층 중앙'), findsNWidgets(2));
    expect(find.text('북악관 B1'), findsOneWidget);
    expect(find.bySemanticsLabel('1층로 이동'), findsOneWidget);
    expect(find.textContaining('둘러봐요'), findsNothing);
  });

  testWidgets('건물 거리뷰는 건물 대표 지점에서 연다', (tester) async {
    await _pump(tester, '/explore?building=bukak');

    expect(find.text('북악관 1F'), findsOneWidget);
  });

  testWidgets('일반 사진 지점은 안내 문구와 이동 칩을 보여준다 (E-08)', (tester) async {
    final container = await _pump(tester, '/');
    container
        .read(tripProvider.notifier)
        .setFrom(const CampusPlace(id: 'hill_entrance', name: '폭풍의언덕 입'));
    GoRouter.of(tester.element(find.text('home'))).push('/explore');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('이 지점은 일반 사진이에요 (360 재촬영 필요)'), findsOneWidget);
    expect(find.text('폭풍의언덕 입'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('제보 깃발은 지금 지점을 담아 제보로 간다', (tester) async {
    await _pump(tester, '/explore');

    await _tap(tester, find.bySemanticsLabel('제보하기'));
    expect(find.text('page /report?node=gate_front'), findsOneWidget);
    await _settleToast(tester);
  });

  testWidgets('보정 모드가 아니면 방향 보정 패널이 없다', (tester) async {
    await _pump(tester, '/explore');

    expect(find.textContaining('방향 보정 모드'), findsNothing);
    expect(
      tester.widget<PanoramaViewer>(find.byType(PanoramaViewer)).onTap,
      isNull,
    );
    await _settleToast(tester);
  });

  testWidgets('방향 보정 모드는 고른 길의 방향을 사진 탭으로 고친다 (A-01)', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(tester, '/explore', launch: {'edit': '1'});

    expect(
      find.text('방향 보정 모드 — 길을 고른 뒤, 사진에서 그 길이 보이는 곳을 탭하세요.'),
      findsOneWidget,
    );
    expect(find.text('보정값 복사 (0)'), findsOneWidget);
    expect(find.text('정문 앞 3갈래 교차로 6°'), findsOneWidget);

    await _tap(tester, find.text('정문 앞 3갈래 교차로 6°'));
    tester.widget<PanoramaViewer>(find.byType(PanoramaViewer)).onTap!(
      -90,
      0,
      0,
    );
    await tester.pump();
    expect(find.text('정문 앞 3갈래 교차로 270°'), findsOneWidget);
    expect(find.text('보정값 복사 (1)'), findsOneWidget);

    await _tap(tester, find.text('보정값 복사 (1)'));
    // The arrow passes a hidden photo, so the fix is keyed to that link
    expect(copied.single, '{"gate_front>parking_3way":270.0}');
    expect(find.text('보정값 1개를 복사했어요'), findsOneWidget);
    await _settleToast(tester);
  });

  testWidgets('없는 건물·층으로 열면 정문에서 연다', (tester) async {
    await _pump(tester, '/explore?building=nope&floor=99');

    expect(find.text('정문 앞'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('서버에만 있는 지점은 지도 위치 준비 중과 연결 없음 안내를 보여준다', (tester) async {
    addTearDown(resetSpots);
    registerSpots(const [
      PanoSpot(
        id: 'EJ1_02_E',
        title: '은주1관 2층 동쪽',
        building: 'eunju1',
        floor: '2층',
      ),
    ]);
    await _pump(tester, '/explore', launch: {'from': 'EJ1_02_E'});

    expect(find.text('은주1관 2층 동쪽'), findsNWidgets(2));
    expect(find.text('지도 위치 준비 중'), findsOneWidget);
    expect(find.text('이 지점은 아직 이동 연결이 없어요'), findsOneWidget);
    await _settleToast(tester);

    await _tap(tester, find.bySemanticsLabel('미니맵'));
    await _tap(tester, find.text('여기서 출발'));
    expect(find.text('page /search?pick=to'), findsOneWidget);
  });

  testWidgets('사진을 못 불러오면 다시 시도할 수 있다', (tester) async {
    var broken = true;
    final bad = MemoryImage(Uint8List.fromList([0, 1, 2, 3]));
    await _pump(tester, '/explore', photo: (_) => broken ? bad : _pixel);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    final error = find.text('사진을 불러오지 못했어요 · 다시 시도');
    expect(error, findsOneWidget);
    broken = false;
    await tester.tap(error);
    await tester.pump();
    await tester.pump();
    expect(error, findsNothing);
    await _settleToast(tester);
  });

  testWidgets('방향을 모르는 서버 연결은 사진 아래 칩으로 이동한다', (tester) async {
    addTearDown(() {
      resetSpots();
      resetLinks();
    });
    const server = PanoSpot(
      id: 'EJ1_02_E',
      title: '은주1관 2층 동쪽',
      building: 'eunju1',
      floor: '2층',
    );
    await _pump(
      tester,
      '/explore',
      overrides: [
        campusMapRepositoryProvider.overrideWithValue(
          _Map(
            CampusMap(
              spots: [spotById['gate_front']!, server],
              links: const [
                (
                  'gate_front',
                  RouteLink(to: 'EJ1_02_E', via: Via.walk, fromServer: true),
                ),
              ],
              places: const [],
            ),
          ),
        ),
      ],
    );
    await _settleToast(tester);

    await _tap(tester, find.text('은주1관 2층 동쪽'));
    expect(find.text('은주1관 2층 동쪽'), findsNWidgets(2));
    await _settleToast(tester);
  });

  testWidgets('지도 데이터를 못 받으면 눌러서 다시 받는다', (tester) async {
    final map = _Map(null);
    await _pump(
      tester,
      '/explore',
      overrides: [campusMapRepositoryProvider.overrideWithValue(map)],
    );

    final retry = find.text('인터넷 연결을 확인해 주세요. 눌러서 다시 시도해 주세요.');
    expect(retry, findsOneWidget);
    map.result = const CampusMap(spots: panoSpots, links: [], places: []);
    await tester.tap(retry);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.text('여기서 출발'), findsOneWidget);
    await _settleToast(tester);
  });
}

class _Map implements CampusMapRepository {
  _Map(this.result);

  CampusMap? result;

  @override
  Future<CampusMap> load() async => result ?? (throw const NetworkException());
}
