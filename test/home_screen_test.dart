import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/home/presentation/screens/home_screen.dart';

GoRouter _router(String initial) {
  Widget page(GoRouterState state) => Scaffold(body: Text('page ${state.uri}'));
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      for (final path in [
        AppRoutes.search,
        AppRoutes.navigation,
        AppRoutes.explore,
        AppRoutes.report,
      ])
        GoRoute(path: path, builder: (_, state) => page(state)),
    ],
  );
}

Future<void> _pumpHome(WidgetTester tester, [String initial = '/']) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router(initial);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [routerProvider.overrideWithValue(router)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

String? _pushed(WidgetTester tester) {
  final page = find.textContaining('page ');
  if (page.evaluate().isEmpty) return null;
  return (tester.widget<Text>(page).data ?? '').substring(5);
}

void main() {
  testWidgets('처음에는 출발·도착이 비어 있고 길찾기가 비활성이다 (H-01)', (tester) async {
    await _pumpHome(tester);

    expect(find.text('출발지 선택 (NFC 태그 시 자동)'), findsOneWidget);
    expect(find.text('도착지 선택'), findsOneWidget);
    expect(find.text('🚧 지금 못 가는 곳 2곳'), findsNothing);

    await _tap(tester, find.text('길찾기'));
    expect(_pushed(tester), isNull);
  });

  testWidgets('출발지 없이 자주 찾는 곳을 고르면 출발지 고르기로 간다 (H-03)', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('골프장'));
    expect(_pushed(tester), '/search?pick=from&to=r-yudam-303');
  });

  testWidgets('NFC 출발지가 있으면 자주 찾는 곳을 고르자마자 길안내로 간다 (H-04·H-05)', (
    tester,
  ) async {
    await _pumpHome(tester, '/?src=nfc&from=bus_stop');
    expect(find.text('버스정류장'), findsOneWidget);

    await _tap(tester, find.text('본관').first);
    expect(
      _pushed(tester),
      '/navigation?from=bus_stop&to=b-bonkwan&mode=outdoor',
    );
  });

  testWidgets('이동 방식·바꾸기·길찾기가 동작한다 (H-06~H-08)', (tester) async {
    await _pumpHome(tester, '/?from=bus_stop&to=b-hyein');

    await _tap(tester, find.text('엘리베이터 우선'));
    await _tap(tester, find.bySemanticsLabel('출발지·도착지 바꾸기'));

    final from = tester.getTopLeft(find.text('혜인관').first).dy;
    final to = tester.getTopLeft(find.text('버스정류장')).dy;
    expect(from, lessThan(to));

    await _tap(tester, find.text('길찾기'));
    expect(
      _pushed(tester),
      '/navigation?from=b-hyein&to=bus_stop&mode=elevator',
    );
  });

  testWidgets('못 가는 곳 카드와 비 오는 날 상태를 보여준다 (H-09·H-21)', (tester) async {
    await _pumpHome(tester, '/?closures=demo&weather=rain');

    expect(find.text('🚧 지금 못 가는 곳 2곳'), findsOneWidget);
    expect(find.text('본관 오르막 2갈래 · 엘리베이터 고장 · 10/12까지'), findsOneWidget);
    expect(find.text('지금 캠퍼스에 비가 와요'), findsOneWidget);
    expect(find.text('지붕 있는 실내·지하 길로 먼저 안내해요'), findsOneWidget);

    await _tap(tester, find.text('지금 캠퍼스에 비가 와요'));
    expect(find.text('켜면 비를 덜 맞는 길로 안내해요'), findsOneWidget);
  });

  testWidgets('편의시설 필터와 지상·지하 전환 (H-10·H-16)', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('매점·편의점'));
    expect(find.text('편의시설 핀을 눌러보세요'), findsOneWidget);
    expect(find.text('청운관 이마트24 편의점'), findsOneWidget);
    expect(find.text('유담관 매점'), findsOneWidget);
    expect(find.text('지하에 1곳 더 있어요 — 오른쪽 위 지하 버튼'), findsOneWidget);

    await _tap(tester, find.text('지하'));
    expect(find.text('북악관 GS25 편의점'), findsOneWidget);
    expect(find.text('지상에 2곳 더 있어요 — 오른쪽 위 지상 버튼'), findsOneWidget);
  });

  testWidgets('지하 지도에서 건물 핀과 연결 안내를 보여준다 (H-17)', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('지하'));
    expect(find.textContaining('지하 제1주차장은'), findsOneWidget);
    expect(find.text('크리에이티브센터'), findsOneWidget);
  });

  testWidgets('같은 곳에 시설이 여럿이면 고르는 시트를 띄운다', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('식당'));
    await _tap(tester, find.text('청운관 수유리우동 외 1'));
    expect(find.text('어디로 갈까요?'), findsNWidgets(2));

    await _tap(tester, find.text('노브랜드버거'));
    expect(_pushed(tester), '/search?pick=from&to=r-chungwoon-957');
  });

  testWidgets('건물 핀을 누르면 건물 시트를 띄운다 (H-18·H-20)', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('본관').last);
    expect(find.text('군사학과'), findsOneWidget);
    expect(find.text('총장실 (301호)'), findsOneWidget);
    expect(find.text('교수 연구실·강의실 27곳 — 검색창에 호수나 이름을 입력하세요'), findsOneWidget);

    await _tap(tester, find.text('여기로 길찾기'));
    expect(_pushed(tester), '/search?pick=from&to=b-bonkwan');
  });

  testWidgets('건물 시트에서 출발지를 정하고 층 거리뷰로 간다 (H-19)', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('유담관'));
    expect(find.text('공공인재학부, 예술교육원'), findsOneWidget);
    await _tap(tester, find.text('여기서 출발'));
    expect(find.text('유담관'), findsWidgets);
    expect(find.text('출발지 선택 (NFC 태그 시 자동)'), findsNothing);

    await _tap(tester, find.text('유담관').last);
    await _tap(tester, find.bySemanticsLabel('L 거리뷰'));
    expect(_pushed(tester), '/explore?building=yudam&floor=L');
  });

  testWidgets('하단 탭과 검색창이 각 화면으로 연결된다', (tester) async {
    await _pumpHome(tester);

    await _tap(tester, find.text('건물, 부서, 교수님 연구실 검색'));
    expect(_pushed(tester), '/search');
  });

  for (final (label, path) in [
    ('지도', '/explore'),
    ('말로 길 묻기', '/search?mode=voice'),
    ('제보', '/report'),
  ]) {
    testWidgets('$label 탭은 $path 로 간다', (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
      expect(_pushed(tester), path);
    });
  }
}
