import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smap/app.dart';
import 'package:smap/core/router.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/navigation/data/guide_voice.dart';
import 'package:smap/features/navigation/state/navigation_controller.dart';
import 'package:smap/features/splash/presentation/screens/splash_screen.dart';

final _pixel = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  ),
);

class _SilentVoice implements GuideVoice {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

// Launch the whole app from a link, past the splash
Future<GoRouter> _launch(
  WidgetTester tester, {
  String link = '/',
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final router = buildRouter(initialLocation: link);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        routerProvider.overrideWithValue(router),
        guideVoiceProvider.overrideWithValue(_SilentVoice()),
        photoImageProvider.overrideWithValue((_) => _pixel),
      ],
      child: const SmapApp(),
    ),
  );
  await tester.pump();
  await tester.tap(find.byType(SplashScreen));
  await tester.pumpAndSettle();
  return router;
}

// Viewer screens keep a loading spinner, so pump fixed frames
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await _frames(tester);
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

String _location(GoRouter router) => router.state.uri.toString();

TripState _trip(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(SmapApp)))
        .read(tripProvider);

// Let the launch notice and toasts finish before the test ends
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await _frames(tester);
}

void main() {
  testWidgets('NFC 진입 → 홈 출발지 → 자주 찾는 곳 → 길안내 → 뒤로 가면 상태 유지', (tester) async {
    final router = await _launch(tester, link: '/?src=nfc&from=bus_stop');
    expect(find.text('버스정류장'), findsOneWidget);

    await _tap(tester, find.text('본관').first);
    expect(
      _location(router),
      startsWith('/navigation?from=bus_stop&to=b-bonkwan'),
    );
    expect(find.textContaining('단계'), findsWidgets);

    router.pop();
    await _frames(tester);
    expect(_location(router), '/?src=nfc&from=bus_stop');
    expect(_trip(tester).from?.id, 'bus_stop');
    expect(_trip(tester).to?.id, 'b-bonkwan');
    await _settle(tester);
  });

  testWidgets('지도 탭 → 둘러보기 → 여기서 출발 → 도착지 검색 → 길안내, 뒤로 가면 홈', (tester) async {
    final router = await _launch(tester);

    await _tap(tester, find.bySemanticsLabel('지도'));
    expect(_location(router), '/explore');
    await _tap(tester, find.text('여기서 출발'));
    expect(_location(router), '/search?pick=to');

    await tester.enterText(find.byType(TextField), '북악');
    await tester.pump();
    await _tap(tester, find.text('북악관'));
    expect(
      _location(router),
      '/navigation?from=gate_front&to=b-bukak&mode=outdoor',
    );

    router.pop();
    await _frames(tester);
    expect(_location(router), '/');
    expect(find.text('정문 앞'), findsOneWidget);
    expect(find.text('북악관'), findsWidgets);
    await _settle(tester);
  });

  testWidgets('홈 → 도착지 검색 → 출발지 선택 → 길안내', (tester) async {
    final router = await _launch(tester);

    await _tap(tester, find.text('건물, 부서, 교수님 연구실 검색'));
    await tester.enterText(find.byType(TextField), '유담');
    await tester.pump();
    await _tap(tester, find.text('유담관').first);
    expect(find.text('어디에서 출발하나요?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '북악');
    await tester.pump();
    await _tap(tester, find.text('북악관'));
    expect(
      _location(router),
      '/navigation?from=b-bukak&to=b-yudam&mode=outdoor',
    );
    await _settle(tester);
  });

  testWidgets('없는 경로로 열면 홈으로 간다', (tester) async {
    final router = await _launch(tester, link: '/nope?x=1');
    expect(_location(router), '/');
    expect(find.text('도착지 선택'), findsOneWidget);
    await _settle(tester);
  });

  for (final width in [375.0, 430.0]) {
    testWidgets('너비 $width에서 홈·둘러보기(보정 모드)가 깨지지 않는다', (tester) async {
      final router = await _launch(tester, link: '/?edit=1', width: width);
      await tester.scrollUntilVisible(
        find.text('지하'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      router.push('/explore');
      await _frames(tester);
      expect(find.textContaining('방향 보정 모드'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _settle(tester);
    });
  }
}
