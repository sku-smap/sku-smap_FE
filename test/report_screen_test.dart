import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/home/presentation/widgets/pressable.dart';
import 'package:smap/features/report/data/mock_report_repository.dart';
import 'package:smap/features/report/data/report_models.dart';
import 'package:smap/features/report/presentation/screens/my_reports_screen.dart';
import 'package:smap/features/report/presentation/screens/report_screen.dart';
import 'package:smap/features/report/presentation/widgets/applied_notice.dart';
import 'package:smap/features/report/state/report_providers.dart';

GoRouter _router() {
  Widget page(GoRouterState state) => Scaffold(body: Text('page ${state.uri}'));
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: AppRoutes.report,
        pageBuilder: (_, state) => ReportScreen.page(state),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (_, _) => const MyReportsScreen(),
      ),
      GoRoute(path: AppRoutes.search, builder: (_, state) => page(state)),
    ],
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  String location, {
  bool online = false,
  String? photo,
  CampusPlace? from,
  bool freshDevice = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (freshDevice) SharedPreferences.setMockInitialValues({});
  final router = _router();
  final container = ProviderContainer(
    overrides: [
      routerProvider.overrideWithValue(router),
      launchQueryProvider.overrideWithValue(const {}),
      reportRepositoryProvider.overrideWithValue(
        MockReportRepository(online: online),
      ),
      photoPickerProvider.overrideWithValue(() async => photo),
    ],
  );
  addTearDown(container.dispose);
  if (from != null) {
    container.read(tripProvider.notifier).setFrom(from);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.push(location);
  await tester.pumpAndSettle();
  return container;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

bool _sendEnabled(WidgetTester tester) {
  final button = find.ancestor(
    of: find.text('보내기'),
    matching: find.byType(Pressable),
  );
  return tester.widget<Pressable>(button).onTap != null;
}

Future<void> _send(WidgetTester tester) async {
  await tester.ensureVisible(find.text('보내기'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('보내기'));
  await tester.pump();
  expect(find.text('보내는 중…'), findsOneWidget);
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pumpAndSettle();
}

Future<List<Map<String, dynamic>>> _stored(WidgetTester tester) async {
  final prefs = await tester.runAsync(SharedPreferences.getInstance);
  return (jsonDecode(prefs!.getString('smap.myReports') ?? '[]') as List)
      .cast<Map<String, dynamic>>();
}

void main() {
  testWidgets('제보 탭은 종류 고르기부터 연다 (R-01)', (tester) async {
    await _pump(tester, '/report');

    expect(find.text('무엇을 알려주실래요?'), findsOneWidget);
    for (final t in ['정보가 틀려요', '지금 못 가요', '더 좋은 길 알려줄게요', '안내가 정확해요']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('home'), findsOneWidget);

    await _tap(tester, find.text('내 제보 현황 보기 ›'));
    expect(find.text('내 제보 현황'), findsOneWidget);
    await _tap(tester, find.bySemanticsLabel('닫기'));
    expect(find.text('home'), findsOneWidget);
    expect(find.text('무엇을 알려주실래요?'), findsNothing);
  });

  testWidgets('정보가 틀려요는 유형이나 내용이 있어야 보낸다 (R-02~R-05)', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('정보가 틀려요'));

    expect(find.text('위치 없음 (내용에 적어주세요)'), findsOneWidget);
    expect(find.text('어디가 어떻게 달랐는지 적어주세요 (선택)'), findsOneWidget);
    expect(_sendEnabled(tester), isFalse);

    await _tap(tester, find.text('이동 방향(화살표)이 틀려요'));
    expect(_sendEnabled(tester), isTrue);
    await _tap(tester, find.text('이동 방향(화살표)이 틀려요'));
    expect(_sendEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), '유담관 3갈래에서 화살표가 반대쪽을 가리켜요');
    await tester.pump();
    expect(_sendEnabled(tester), isTrue);

    await _send(tester);
    expect(find.text('알려줘서 고마워요! 확인하고 반영할게요.'), findsOneWidget);
    expect(find.text('home'), findsOneWidget);

    // Server not connected: kept on this device without a location
    final stored = await _stored(tester);
    expect(stored.single['kind'], 'issue');
    expect(stored.single['node'], 'home');
    expect(stored.single['memo'], '유담관 3갈래에서 화살표가 반대쪽을 가리켜요');

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('알려줘서 고마워요! 확인하고 반영할게요.'), findsNothing);
  });

  testWidgets('종류 다시 고르기로 돌아간다', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('안내가 정확해요'));
    await _tap(tester, find.bySemanticsLabel('종류 다시 고르기'));
    expect(find.text('무엇을 알려주실래요?'), findsOneWidget);
  });

  testWidgets('지금 못 가요는 출발지를 위치로 쓰고 무슨 일·기간을 고른다 (R-06·R-08·R-09)', (
    tester,
  ) async {
    await _pump(
      tester,
      '/report',
      from: const CampusPlace(id: 'b-bukak', name: '북악관'),
    );
    await _tap(tester, find.text('지금 못 가요'));

    expect(find.text('팀이 확인하면 다른 사람의 길안내가 이 지점을 피해서 가요.'), findsOneWidget);
    expect(find.text('북악관'), findsOneWidget);
    expect(_sendEnabled(tester), isFalse);

    await _tap(tester, find.text('지도에서'));
    expect(find.text('지도를 누르면 가장 가까운 촬영 지점이 골라져요'), findsOneWidget);
    await _tap(tester, find.text('지도에서'));
    expect(find.text('지도를 누르면 가장 가까운 촬영 지점이 골라져요'), findsNothing);

    await _tap(tester, find.text('엘리베이터 고장'));
    await _tap(tester, find.text('잘 모르겠어요'));
    expect(_sendEnabled(tester), isTrue);

    await _send(tester);
    expect(find.text('고마워요! 확인되면 길안내가 이 지점을 피해 가요.'), findsOneWidget);
    final stored = (await _stored(tester)).single;
    expect(stored['type'], '엘리베이터 고장');
    expect(stored['until'], isNull);
    expect(stored['node'], isNot('home'));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('위치는 검색으로도 고른다 (R-07)', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('안내가 정확해요'));
    expect(find.text('위치를 골라주세요'), findsOneWidget);
    expect(_sendEnabled(tester), isFalse);

    await _tap(tester, find.text('검색'));
    expect(find.text('어디인가요?'), findsOneWidget);
    await _tap(tester, find.text('본관').first);

    expect(find.text('어디인가요?'), findsNothing);
    expect(find.text('본관'), findsOneWidget);
    expect(_sendEnabled(tester), isTrue);
    expect(find.text('사진 (선택)'), findsNothing);
  });

  testWidgets('현장 사진을 붙이고 뺀다 (R-10)', (tester) async {
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('report'),
    );
    final file = File('${dir!.path}/site.png');
    await tester.runAsync(
      () => file.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        ),
      ),
    );
    addTearDown(() => dir.deleteSync(recursive: true));
    await _pump(tester, '/report', photo: file.path);
    await _tap(tester, find.text('지금 못 가요'));

    await _tap(tester, find.text('📷 현장 사진 추가'));
    expect(find.bySemanticsLabel('첨부한 사진'), findsOneWidget);
    await _tap(tester, find.text('사진 빼기'));
    expect(find.text('📷 현장 사진 추가'), findsOneWidget);
  });

  testWidgets('더 좋은 길은 출발·도착과 태그나 내용이 있어야 보낸다 (R-11·R-12)', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('더 좋은 길 알려줄게요'));

    expect(find.text('어디서 출발하나요?'), findsOneWidget);
    expect(find.text('어디까지 가는 길인가요?'), findsOneWidget);

    await _tap(tester, find.text('어디서 출발하나요?'));
    expect(find.text('어디서 출발하는 길인가요?'), findsOneWidget);
    await _tap(tester, find.text('혜인관'));
    await _tap(tester, find.text('어디까지 가는 길인가요?'));
    await _tap(tester, find.text('혜인관').last);
    await _tap(tester, find.text('짐 많을 때'));
    // Same start and end is not a course
    expect(_sendEnabled(tester), isFalse);

    await _tap(tester, find.text('혜인관').last);
    await _tap(tester, find.text('본관').last);
    await _tap(tester, find.text('엘리베이터 위주'));
    expect(_sendEnabled(tester), isTrue);

    await _send(tester);
    final stored = (await _stored(tester)).single;
    expect(stored['type'], '짐 많을 때, 엘리베이터 위주');
    expect(stored['tags'], ['짐 많을 때', '엘리베이터 위주']);
    expect(stored['from_node'], isNot(stored['to_node']));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('거리뷰 깃발은 그 지점을 위치로 연다 (R-18)', (tester) async {
    await _pump(tester, '/report?node=gate_front&step=2');
    expect(find.text('무엇을 알려주실래요?'), findsOneWidget);
    await _tap(tester, find.text('정보가 틀려요'));
    expect(find.text('정문 앞'), findsOneWidget);
  });

  testWidgets('종류가 정해져 오면 바로 그 화면이고 뒤로 버튼이 없다', (tester) async {
    await _pump(tester, '/report?node=gate_front&kind=issue');
    expect(find.text('⚠️ 정보가 틀려요'), findsOneWidget);
    expect(find.bySemanticsLabel('종류 다시 고르기'), findsNothing);
  });

  testWidgets('시트 바깥을 누르면 닫힌다', (tester) async {
    await _pump(tester, '/report');
    await tester.tapAt(const Offset(195, 100));
    await tester.pumpAndSettle();
    expect(find.text('무엇을 알려주실래요?'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('내 제보 현황은 처리 단계를 보여준다 (R-15)', (tester) async {
    await _pump(tester, '/report/mine', online: true);

    expect(find.text('서버 연결 전이라 이 기기에 저장된 제보만 보여요.'), findsNothing);
    expect(find.text('더 좋은 길 알려줄게요'), findsOneWidget);
    expect(find.text('🎉 반영됐어요. 덕분에 길안내가 더 정확해졌어요!'), findsOneWidget);
    expect(find.text('본관 오르막 2갈래'), findsOneWidget);
    expect(find.bySemanticsLabel('처리 상태: 확인 중'), findsOneWidget);
    expect(find.text('유담관 3갈래 교차로'), findsOneWidget);
    expect(find.bySemanticsLabel('처리 상태: 받음'), findsOneWidget);
    expect(find.text('위치 없이 보낸 제보'), findsOneWidget);
    expect(find.text('기타 — 지도 글씨가 작아요'), findsOneWidget);
    expect(find.text('이번엔 반영하지 못했어요. 알려줘서 고마워요!'), findsOneWidget);
    expect(find.text('10월 9일'), findsOneWidget);
  });

  testWidgets('서버 연결 전에는 이 기기 제보만 보인다 (R-16)', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('정보가 틀려요'));
    await _tap(tester, find.text('기타'));
    await _send(tester);
    await tester.pump(const Duration(seconds: 4));

    GoRouter.of(tester.element(find.text('home'))).push('/report/mine');
    await tester.pumpAndSettle();
    expect(find.text('서버 연결 전이라 이 기기에 저장된 제보만 보여요.'), findsOneWidget);
    expect(find.text('위치 없이 보낸 제보'), findsOneWidget);
    expect(find.text('이 기기에만 저장됨 · 서버가 연결되면 다시 보내 주세요'), findsOneWidget);
  });

  testWidgets('보낸 제보가 없으면 빈 화면을 보여준다 (R-17)', (tester) async {
    await _pump(tester, '/report/mine');
    expect(find.text('서버 연결 전이라 이 기기에 저장된 제보만 보여요.'), findsOneWidget);
    expect(
      find.text('아직 보낸 제보가 없어요.\n길이 헷갈리거나 못 가는 곳이 있으면 알려주세요!'),
      findsOneWidget,
    );
  });

  testWidgets('반영된 제보는 앱을 열 때 한 번만 알려준다 (R-14)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Future<void> open() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(
              MockReportRepository(online: true),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: Stack(children: [ReportAppliedNotice()])),
          ),
        ),
      );
    }

    const notice = "🎉 제보하신 '더 좋은 길 알려줄게요'이 반영됐어요. 고마워요!";
    await open();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text(notice), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text(notice), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(notice), findsNothing);

    // Already seen on the next launch
    await tester.pumpWidget(const SizedBox());
    await open();
    await tester.pump(const Duration(seconds: 3));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text(notice), findsNothing);
  });

  testWidgets('앱을 다시 열어도 이 기기에 저장한 제보를 복원한다', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('정보가 틀려요'));
    await _tap(tester, find.text('기타'));
    await _send(tester);
    await tester.pump(const Duration(seconds: 4));

    // Relaunch: new providers, same device storage
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, '/report/mine', freshDevice: false);
    expect(find.text('위치 없이 보낸 제보'), findsOneWidget);
    expect(find.text('이 기기에만 저장됨 · 서버가 연결되면 다시 보내 주세요'), findsOneWidget);
  });

  testWidgets('검색 화면의 음성으로 고른 곳이 제보 위치가 된다', (tester) async {
    await _pump(tester, '/report');
    await _tap(tester, find.text('안내가 정확해요'));
    await _tap(tester, find.text('검색'));
    await _tap(tester, find.bySemanticsLabel('음성으로 검색'));
    expect(find.text('page /search?mode=voice&for=report'), findsOneWidget);

    GoRouter.of(tester.element(find.textContaining('page ')))
        .pop(const CampusPlace(id: 'b-bonkwan', name: '본관'));
    await tester.pumpAndSettle();
    expect(find.text('어디인가요?'), findsNothing);
    expect(find.text('본관'), findsOneWidget);
    expect(_sendEnabled(tester), isTrue);
  });

  test('mock 처리 상태가 반영됨으로 바뀌면 다음 실행 때 한 번 알려준다', () async {
    SharedPreferences.setMockInitialValues({});
    final server = MockReportRepository(online: true);
    Future<String?> launch() async {
      final c = ProviderContainer(
        overrides: [reportRepositoryProvider.overrideWithValue(server)],
      );
      addTearDown(c.dispose);
      return c.read(appliedNoticeProvider.future);
    }

    expect(await launch(), contains('더 좋은 길 알려줄게요'));
    expect(await launch(), isNull);

    server.setStatus(103, ReportStatus.applied);
    expect(await launch(), "🎉 제보하신 '지금 못 가요'이 반영됐어요. 고마워요!");
    expect(await launch(), isNull);
  });
}
