import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/home/data/campus_models.dart';
import 'package:smap/features/explore/presentation/screens/explore_screen.dart';
import 'package:smap/features/home/state/home_controller.dart';
import 'package:smap/features/home/state/home_entry_provider.dart';
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
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router(initial);
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      homeLaunchQueryProvider.overrideWithValue(launch),
      photoImageProvider.overrideWithValue((_) => _pixel),
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
    final from = container.read(homeControllerProvider).from;
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
        .read(homeControllerProvider.notifier)
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
}
