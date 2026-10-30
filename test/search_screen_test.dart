import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/core/network/app_exception.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/home/state/home_notice.dart';
import 'package:smap/features/search/data/mock_search_repository.dart';
import 'package:smap/features/search/data/place_search.dart';
import 'package:smap/features/search/data/search_models.dart';
import 'package:smap/features/search/data/search_repository.dart';
import 'package:smap/features/search/data/voice_recorder.dart';
import 'package:smap/features/search/presentation/screens/search_screen.dart';
import 'package:smap/features/search/state/place_search_controller.dart';
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
  SearchRepository? repo,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router(initial);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        searchRepositoryProvider.overrideWithValue(
          repo ?? MockSearchRepository(transcript: transcript ?? ''),
        ),
        voiceRecorderProvider.overrideWithValue(_FakeRecorder()),
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

// Let the search debounce pass and the result arrive
Future<void> _typed(WidgetTester tester) async {
  await tester.pump(PlaceSearchController.debounce);
  await tester.pump();
}

class _FakeRecorder implements VoiceRecorder {
  @override
  Future<bool> start() async => true;

  @override
  Future<VoiceClip?> stop() async => VoiceClip(
    bytes: Uint8List.fromList([1, 2, 3]),
    duration: const Duration(seconds: 2),
  );

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
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
    await _typed(tester);
    expect(find.text('행정사무실(교무처, 교육혁신처) (101호)'), findsOneWidget);
    expect(find.text('자주 찾는 곳'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ㅁㄴㅇ');
    await _typed(tester);
    expect(find.textContaining('‘ㅁㄴㅇ’ 검색 결과가 없어요'), findsOneWidget);
  });

  testWidgets('출발지가 없으면 도착지를 고른 뒤 출발지 고르기로 넘어간다 (S-09·S-10)', (tester) async {
    final container = await _pumpSearch(tester, '/search');

    await tester.enterText(find.byType(TextField), '교무');
    await _typed(tester);
    await _tap(tester, find.text('행정사무실(교무처, 교육혁신처) (101호)'));

    expect(container.read(tripProvider).to?.id, 'r-hyein-101');
    expect(find.text('어디에서 출발하나요?'), findsOneWidget);
    expect(find.textContaining('까지 안내할게요. 지금 계신 곳을 골라주세요'), findsOneWidget);
    expect(find.text('현재 위치로'), findsNothing);
    expect(find.text('지도에서 고르기'), findsOneWidget);

    await _wait(tester, 3200);
    await _wait(tester, 300);
    expect(find.textContaining('까지 안내할게요'), findsNothing);
  });

  testWidgets('출발·도착이 다 정해지면 길안내 대신 홈 경로 카드로 돌아간다', (tester) async {
    final container = await _pumpSearch(tester, '/search?pick=from');
    container
        .read(tripProvider.notifier)
        .setTo(const CampusPlace(id: 'b-bonkwan', name: '본관'));

    await tester.enterText(find.byType(TextField), '북악');
    await _typed(tester);
    await _tap(tester, find.text('북악관'));
    expect(_pushed(tester), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(container.read(tripProvider).from?.id, 'b-bukak');
  });

  testWidgets('링크로 받은 도착지가 이전 도착지보다 우선한다', (tester) async {
    final container = await _pumpSearch(
      tester,
      '/search?pick=from&to=b-bonkwan',
    );
    await tester.pump();

    expect(container.read(tripProvider).to?.id, 'b-bonkwan');
    expect(find.text('본관까지 안내할게요. 지금 계신 곳을 골라주세요'), findsOneWidget);
    await _wait(tester, 3600);
  });

  testWidgets('출발지 검색은 360 촬영 지점도 찾는다 (S-12)', (tester) async {
    await _pumpSearch(tester, '/search?pick=from');

    await tester.enterText(find.byType(TextField), '북악관 1층 중앙');
    await _typed(tester);
    expect(find.text('360 촬영 지점'), findsWidgets);
  });

  testWidgets('지도에서 고르기를 펼친다 (S-11)', (tester) async {
    await _pumpSearch(tester, '/search?pick=from');

    await _tap(tester, find.text('지도에서 고르기'));
    expect(find.text('지상'), findsOneWidget);
    expect(find.text('지하'), findsOneWidget);
  });

  testWidgets('예시 문장으로 바로 도착지를 정한다 (S-15·S-16)', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');

    expect(find.text('듣고 있어요… 다 말하면 버튼을 누르세요'), findsOneWidget);
    await _tap(tester, find.text('유담관이 어디에요?').last);
    expect(find.text('찾는 중…'), findsOneWidget);
    await _wait(tester, 700);

    expect(container.read(tripProvider).to?.id, 'b-yudam');
    expect(container.read(tripProvider).from, isNull);
    expect(find.text('home'), findsOneWidget);
    expect(
      container.read(homeNoticeProvider)?.text,
      '출발지를 인식하지 못했습니다. 출발지를 입력해주세요.',
    );
  });

  testWidgets('말을 멈추면 알아듣고 후보를 보여준다 (S-17~S-19)', (tester) async {
    await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.bySemanticsLabel('그만 듣기'));
    expect(find.text('알아듣는 중…'), findsOneWidget);
    await _wait(tester, 1000);

    expect(find.text('이렇게 들었어요'), findsOneWidget);
    expect(find.text('학생 어디야'), findsOneWidget);
    expect(find.text('혹시 이곳인가요?'), findsOneWidget);
  });

  testWidgets('용무 질문은 그 부서를 도착지로 하고 출발지는 비운다 (S-20·S-21)', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.text('졸업증명서 떼려면 어디로 가요?'));
    await _wait(tester, 700);

    expect(container.read(tripProvider).to?.name, '교무처');
    expect(container.read(tripProvider).from, isNull);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('문장에 출발지가 있으면 둘 다 채우고 홈 경로 카드로 돌아간다 (S-22)', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.text('북악관에서 문예관 가는 길'));
    await _wait(tester, 700);
    expect(_pushed(tester), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(container.read(tripProvider).to?.id, 'b-moonye');
    expect(container.read(tripProvider).from?.id, 'b-bukak');
  });

  testWidgets('계단 말고 라고 하면 편한길로 안내한다', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');
    container
        .read(tripProvider.notifier)
        .setFrom(const CampusPlace(id: 'f-bus', name: '버스정류장'));

    await _tap(tester, find.text('계단 말고 혜인관 가는 길'));
    await _wait(tester, 700);
    expect(container.read(tripProvider).mode, RouteMode.comfortable);
    expect(_pushed(tester), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(container.read(tripProvider).to?.id, 'b-hyein');
  });

  testWidgets('검색창 마이크로 음성 화면을 연다', (tester) async {
    await _pumpSearch(tester, '/search');

    await _tap(tester, find.bySemanticsLabel('음성으로 검색'));
    expect(find.text('이렇게 말해 보세요'), findsOneWidget);
  });

  testWidgets('출발지 고르기에서 음성으로 고르면 출발지로 정한다', (tester) async {
    final container = await _pumpSearch(tester, '/search?pick=from&mode=voice');

    await _tap(tester, find.text('유담관이 어디에요?'));
    await _wait(tester, 700);
    expect(container.read(tripProvider).from?.id, 'b-yudam');
    expect(container.read(tripProvider).to, isNull);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('후보를 누르면 기록을 기다리지 않고 홈 경로 카드로 돌아간다', (tester) async {
    final repo = _SlowSelectRepo();
    final container = await _pumpSearch(
      tester,
      '/search?mode=voice',
      repo: repo,
    );
    container
        .read(tripProvider.notifier)
        .setFrom(const CampusPlace(id: 'f-bus', name: '버스정류장'));

    await _tap(tester, find.text('유담관이 어디에요?'));
    await _tap(tester, find.text('문예관'));
    await _wait(tester, 300);
    expect(_pushed(tester), isNull);
    expect(find.text('home'), findsOneWidget);
    expect(container.read(tripProvider).to?.id, 'b-moonye');
  });

  testWidgets('검색이 실패하면 오류와 다시 시도를 보여준다', (tester) async {
    await _pumpSearch(tester, '/search?mode=voice', repo: _FailingRepo());

    await _tap(tester, find.text('유담관이 어디에요?'));
    expect(find.text('인터넷 연결을 확인해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('출발지만 말하면 출발지만 넣고 도착지는 비운 채 홈으로 간다', (tester) async {
    final container = await _pumpSearch(
      tester,
      '/search?mode=voice',
      repo: _OriginOnlyRepo(),
    );

    await _tap(tester, find.text('유담관이 어디에요?'));
    await _wait(tester, 300);
    expect(container.read(tripProvider).from?.id, 'b-yudam');
    expect(container.read(tripProvider).to, isNull);
    expect(find.text('home'), findsOneWidget);
    expect(
      container.read(homeNoticeProvider)?.text,
      '도착지를 인식하지 못했습니다. 도착지를 입력해주세요.',
    );
  });

  testWidgets('출발·도착을 정해 둔 뒤 다시 말하면 이전 값이 남지 않는다', (tester) async {
    final container = await _pumpSearch(
      tester,
      '/search?mode=voice',
      repo: _OriginOnlyRepo(),
    );
    container.read(tripProvider.notifier)
      ..setFrom(const CampusPlace(id: 'f-gate', name: '정문'))
      ..setTo(const CampusPlace(id: 'b-bonkwan', name: '본관'));

    await _tap(tester, find.text('유담관이 어디에요?'));
    await _wait(tester, 300);
    expect(container.read(tripProvider).from?.id, 'b-yudam');
    expect(container.read(tripProvider).to, isNull, reason: 'old 본관 is gone');
  });

  testWidgets('둘 다 찾으면 경로 설정 완료를 알린다', (tester) async {
    final container = await _pumpSearch(tester, '/search?mode=voice');

    await _tap(tester, find.text('북악관에서 문예관 가는 길'));
    await _wait(tester, 700);
    expect(container.read(homeNoticeProvider)?.text, '경로 설정이 완료되었습니다.');
  });

  testWidgets('도착지 후보가 여럿이면 칩으로 고른 뒤 경로 설정 완료를 알린다', (tester) async {
    final container = await _pumpSearch(
      tester,
      '/search?mode=voice',
      repo: _RouteChipsRepo(),
    );

    await _tap(tester, find.text('유담관이 어디에요?'));
    await _wait(tester, 300);
    expect(find.text('혹시 이곳인가요?'), findsOneWidget);
    expect(find.text('체육시설 (401호)'), findsOneWidget);
    expect(container.read(homeNoticeProvider), isNull, reason: 'not yet');

    await _tap(tester, find.text('체육시설 (401호)'));
    await _wait(tester, 300);
    expect(container.read(tripProvider).from?.id, 'b-bukak');
    expect(container.read(tripProvider).to?.id, 'r-yudam-401');
    expect(find.text('home'), findsOneWidget);
    expect(container.read(homeNoticeProvider)?.text, '경로 설정이 완료되었습니다.');
  });
}

class _SlowSelectRepo implements SearchRepository {
  final selection = Completer<void>();

  @override
  Future<SearchResult> searchText({
    required SearchTarget target,
    required String query,
  }) async => const SearchResult(
    target: SearchTarget.destination,
    searchId: 3,
    candidates: [
      SearchCandidate(
        id: 'place:b-bukak',
        type: CandidateType.place,
        nodeId: 'bukak_1f_main_in',
        name: '북악관',
        placeId: 'b-bukak',
      ),
      SearchCandidate(
        id: 'place:b-moonye',
        type: CandidateType.place,
        nodeId: 'moonye_1f_in',
        name: '문예관',
        placeId: 'b-moonye',
      ),
    ],
  );

  @override
  Future<SearchResult> searchVoice({
    required SearchTarget target,
    required VoiceClip clip,
  }) async => throw const NetworkException();

  @override
  Future<SearchResult> searchRouteText(String query) =>
      searchText(target: SearchTarget.destination, query: query);

  @override
  Future<SearchResult> searchRouteVoice(VoiceClip clip) async =>
      throw const NetworkException();

  @override
  Future<void> select({required int searchId, required String candidateId}) =>
      selection.future;
}

class _FailingRepo implements SearchRepository {
  @override
  Future<SearchResult> searchText({
    required SearchTarget target,
    required String query,
  }) async => throw const NetworkException();

  @override
  Future<SearchResult> searchVoice({
    required SearchTarget target,
    required VoiceClip clip,
  }) async => throw const NetworkException();

  @override
  Future<SearchResult> searchRouteText(String query) async =>
      throw const NetworkException();

  @override
  Future<SearchResult> searchRouteVoice(VoiceClip clip) async =>
      throw const NetworkException();

  @override
  Future<void> select({
    required int searchId,
    required String candidateId,
  }) async {}
}

// The sentence named only the start
class _OriginOnlyRepo extends _FailingRepo {
  @override
  Future<SearchResult> searchRouteText(String query) async =>
      const SearchResult(
        target: SearchTarget.destination,
        message: '어디로 갈지 알려 주세요.',
        origin: SearchCandidate(
          id: 'place:b-yudam',
          type: CandidateType.place,
          nodeId: 'yudam_9f',
          name: '유담관',
          placeId: 'b-yudam',
        ),
      );
}

// Start found and several destinations to choose from
class _RouteChipsRepo extends _FailingRepo {
  @override
  Future<SearchResult> searchRouteText(String query) async =>
      const SearchResult(
        target: SearchTarget.destination,
        searchId: 9,
        origin: SearchCandidate(
          id: 'place:b-bukak',
          type: CandidateType.place,
          nodeId: 'bukak_1f_main_in',
          name: '북악관',
          placeId: 'b-bukak',
        ),
        candidates: [
          SearchCandidate(
            id: 'place:b-yudam',
            type: CandidateType.place,
            nodeId: 'yudam_9f',
            name: '유담관',
            placeId: 'b-yudam',
          ),
          SearchCandidate(
            id: 'place:r-yudam-401',
            type: CandidateType.place,
            nodeId: 'yudam_9f',
            name: '체육시설 (401호)',
            placeId: 'r-yudam-401',
          ),
        ],
      );
}
