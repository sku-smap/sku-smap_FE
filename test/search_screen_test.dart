import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/home/data/campus_models.dart';
import 'package:smap/features/home/state/home_controller.dart';
import 'package:smap/features/search/data/mock_speech.dart';
import 'package:smap/features/search/data/place_search.dart';
import 'package:smap/features/search/presentation/screens/search_screen.dart';
import 'package:smap/features/search/state/search_flow_controller.dart';

GoRouter _router(String initial) {
  return GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home')),
        routes: [
          GoRoute(
            path: 'search',
            builder: (_, state) =>
                SearchScreen(query: state.uri.queryParameters),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.navigation,
        builder: (_, state) => Scaffold(body: Text('page ${state.uri}')),
      ),
    ],
  );
}

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester,
  String initial, {
  String? transcript = '학생 어디야',
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router(initial);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        speechRecognizerProvider.overrideWithValue(
          MockSpeechRecognizer(transcript: transcript),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _wait(WidgetTester tester, int ms) =>
    tester.pump(Duration(milliseconds: ms));

String? _pushed(WidgetTester tester) {
  final page = find.textContaining('page ');
  if (page.evaluate().isEmpty) return null;
  return (tester.widget<Text>(page).data ?? '').substring(5);
}

void main() {
  group('검색 규칙', () {
    test('부서·호실·별명으로 찾는다', () {
      expect(searchPlacesFor('교무').first.id, 'r-hyein-101');
      expect(searchPlacesFor('303').first.name, '스크린골프 (303호)');
      expect(searchPlacesFor('ㅁㄴㅇ'), isEmpty);
    });

    test('문장에서 출발·도착과 계단 회피를 읽는다', () {
      final route = parseUtterance('북악관에서 문예관 가는 길');
      expect(route.from?.id, 'b-bukak');
      expect(route.to?.id, 'b-moonye');

      final stairs = parseUtterance('계단 말고 혜인관 가는 길');
      expect(stairs.to?.id, 'b-hyein');
      expect(stairs.avoidStairs, isTrue);

      final task = parseUtterance('졸업증명서 떼려면 어디로 가요?');
      expect(task.to?.name, '교무처');
      expect(task.reply, startsWith('증명서 발급은 교무처'));
    });
  });

  testWidgets('처음엔 자주 찾는 곳을 보여준다 (S-01)', (tester) async {
    await _pumpSearch(tester, '/search');

    expect(find.text('어디로 갈까요?'), findsOneWidget);
    expect(find.text('자주 찾는 곳'), findsOneWidget);
    expect(find.text('유담관'), findsOneWidget);
    expect(find.text('건물 · 9층 버스정류장 쪽 입구'), findsOneWidget);
  });

  testWidgets('검색 결과와 결과 없음을 보여준다 (S-04·S-08)', (tester) async {
    await _pumpSearch(tester, '/search');

    await tester.enterText(find.byType(TextField), '교무');
    await tester.pump();
    expect(find.text('행정사무실(교무처, 교육혁신처) (101호)'), findsOneWidget);
    expect(find.text('자주 찾는 곳'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ㅁㄴㅇ');
    await tester.pump();
    expect(find.textContaining('‘ㅁㄴㅇ’ 검색 결과가 없어요'), findsOneWidget);
  });

  testWidgets('출발지가 없으면 도착지를 고른 뒤 출발지 고르기로 넘어간다 (S-09·S-10)', (
    tester,
  ) async {
    final container = await _pumpSearch(tester, '/search');

    await tester.enterText(find.byType(TextField), '교무');
    await tester.pump();
    await _tap(tester, find.text('행정사무실(교무처, 교육혁신처) (101호)'));

    expect(container.read(homeControllerProvider).to?.id, 'r-hyein-101');
    expect(find.text('어디에서 출발하나요?'), findsOneWidget);
    expect(find.textContaining('까지 안내할게요. 지금 계신 곳을 골라주세요'), findsOneWidget);
    expect(find.text('현재 위치로'), findsOneWidget);
    expect(find.text('지도에서 고르기'), findsOneWidget);

    await _wait(tester, 3200);
    await _wait(tester, 300);
    expect(find.textContaining('까지 안내할게요'), findsNothing);
  });

  testWidgets('출발·도착이 다 정해지면 길안내로 바꾼다', (tester) async {
    final container = await _pumpSearch(tester, '/search?pick=from');
    container
        .read(homeControllerProvider.notifier)
        .setTo(const CampusPlace(id: 'b-bonkwan', name: '본관'));

    await tester.enterText(find.byType(TextField), '북악');
    await tester.pump();
    await _tap(tester, find.text('북악관'));
    expect(
      _pushed(tester),
      '/navigation?from=b-bukak&to=b-bonkwan&mode=outdoor',
    );
  });

  testWidgets('출발지 검색은 360 촬영 지점도 찾는다 (S-12)', (tester) async {
    await _pumpSearch(tester, '/search?pick=from');

    await tester.enterText(find.byType(TextField), '북악관 1층 중앙');
    await tester.pump();
    expect(find.text('360 촬영 지점'), findsWidgets);
  });

  testWidgets('지도에서 고르기를 펼친다 (S-11)', (tester) async {
    await _pumpSearch(tester, '/search?pick=from');

    await _tap(tester, find.text('지도에서 고르기'));
    expect(find.text('지상'), findsOneWidget);
    expect(find.text('지하'), findsOneWidget);
  });

  testWidgets('학교 밖이면 위치 오류를 보여준다 (S-13)', (tester) async {
    await _pumpSearch(tester, '/search?pick=from');

    await _tap(tester, find.text('현재 위치로'));
    expect(find.text('위치 찾는 중…'), findsOneWidget);
    await _wait(tester, 700);
    expect(find.textContaining('지금 학교 밖이에요'), findsOneWidget);
  });

  testWidgets('캠퍼스 안이면 가장 가까운 지점을 출발지로 넣는다 (S-14)', (tester) async {
    final container = await _pumpSearch(
      tester,
      '/search?pick=from&location=campus',
    );

    await _tap(tester, find.text('현재 위치로'));
    await _wait(tester, 700);
    expect(
      container.read(homeControllerProvider).from?.name,
      startsWith('현재 위치 · '),
    );
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('예시 문장으로 바로 도착지를 정한다 (S-15·S-16)', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');

    expect(find.text('듣고 있어요… 다 말하면 버튼을 누르세요'), findsOneWidget);
    await _tap(tester, find.text('유담관이 어디에요?').last);
    expect(find.text('찾는 중…'), findsOneWidget);
    await _wait(tester, 700);

    expect(container.read(homeControllerProvider).to?.id, 'b-yudam');
    expect(find.text('어디에서 출발하나요?'), findsOneWidget);
  });

  testWidgets('말을 멈추면 알아듣고 후보를 보여준다 (S-17~S-19)', (tester) async {
    await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.bySemanticsLabel('그만 듣기'));
    expect(find.text('알아듣는 중…'), findsOneWidget);
    await _wait(tester, 1000);
    expect(find.text('찾는 중…'), findsOneWidget);
    await _wait(tester, 700);

    expect(find.text('이렇게 들었어요'), findsOneWidget);
    expect(find.text('학생 어디야'), findsOneWidget);
    expect(find.text('혹시 이곳인가요?'), findsOneWidget);
  });

  testWidgets('용무 질문은 답을 보여주고 출발지를 묻는다 (S-20·S-21)', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.text('졸업증명서 떼려면 어디로 가요?'));
    await _wait(tester, 700);

    expect(container.read(homeControllerProvider).to?.name, '교무처');
    expect(find.textContaining('증명서 발급은 교무처'), findsOneWidget);
    expect(find.text('어디에서 출발하나요?'), findsOneWidget);
  });

  testWidgets('문장에 출발지가 있으면 바로 길안내로 간다 (S-22)', (tester) async {
    await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.text('북악관에서 문예관 가는 길'));
    await _wait(tester, 700);
    expect(
      _pushed(tester),
      '/navigation?from=b-bukak&to=b-moonye&mode=outdoor',
    );
  });

  testWidgets('계단 말고 라고 하면 엘리베이터 우선으로 안내한다', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');
    container
        .read(homeControllerProvider.notifier)
        .setFrom(const CampusPlace(id: 'f-bus', name: '버스정류장'));

    await _tap(tester, find.text('계단 말고 혜인관 가는 길'));
    await _wait(tester, 700);
    expect(container.read(homeControllerProvider).mode, RouteMode.elevator);
    expect(
      _pushed(tester),
      '/navigation?from=f-bus&to=b-hyein&mode=elevator',
    );
  });

  testWidgets('검색창 마이크로 음성 화면을 연다', (tester) async {
    await _pumpSearch(tester, '/search');

    await _tap(tester, find.bySemanticsLabel('음성으로 검색'));
    expect(find.text('이렇게 말해 보세요'), findsOneWidget);
  });
}
