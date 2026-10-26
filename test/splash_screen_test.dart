import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/app.dart';
import 'package:smap/core/router.dart';
import 'package:smap/core/widgets/placeholder_page.dart';
import 'package:smap/features/splash/presentation/screens/splash_screen.dart';

Widget _host({
  String? nfcPlace,
  required VoidCallback onDone,
  bool still = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: still,
        size: const Size(390, 844),
      ),
      child: SplashScreen(nfcPlace: nfcPlace, onDone: onDone),
    ),
  );
}

void main() {
  testWidgets('기본 스플래시는 부제를 보여주고 2.2초 뒤 끝난다', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(onDone: () => done++));

    expect(find.text('s'), findsOneWidget);
    expect(find.text('p'), findsOneWidget);
    expect(find.text('서경대 캠퍼스 길찾기'), findsOneWidget);
    expect(find.text('NFC 태그'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2100));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(done, 1);
  });

  testWidgets('NFC 스플래시는 출발 안내를 보여주고 2.8초 뒤 끝난다', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(nfcPlace: '버스정류장', onDone: () => done++));

    expect(find.text('NFC 태그'), findsOneWidget);
    expect(find.text('지금 계신 버스정류장에서\n시작할게요'), findsOneWidget);
    expect(find.text('서경대 캠퍼스 길찾기'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2300));
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 550));
    expect(done, 1);
  });

  testWidgets('화면을 탭하면 바로 끝난다', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(onDone: () => done++));

    await tester.tap(find.byType(SplashScreen));
    expect(done, 1);

    await tester.pump(const Duration(seconds: 3));
    expect(done, 1);
  });

  testWidgets('모션 줄이기 설정이면 1초 뒤 끝난다', (tester) async {
    var done = 0;
    await tester.pumpWidget(_host(still: true, onDone: () => done++));

    await tester.pump(const Duration(milliseconds: 1050));
    expect(done, 1);
  });

  testWidgets('NFC 링크로 열면 스플래시 뒤 홈이 보인다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWithValue(
            GoRouter(
              initialLocation: '/?src=nfc&from=bus_stop',
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) =>
                      const PlaceholderPage(title: '홈'),
                ),
              ],
            ),
          ),
        ],
        child: const SmapApp(),
      ),
    );

    expect(find.text('지금 계신 버스정류장에서\n시작할게요'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(PlaceholderPage), findsOneWidget);
  });
}
