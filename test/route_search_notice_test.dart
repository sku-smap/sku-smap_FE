import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/home/presentation/widgets/home_toast.dart';
import 'package:smap/features/home/state/home_notice.dart';
import 'package:smap/features/search/presentation/screens/search_screen.dart';

void main() {
  test('인식 결과별 안내 문구', () {
    expect(routeSearchNotice(from: true, to: true), '경로 설정이 완료되었습니다.');
    expect(
      routeSearchNotice(from: false, to: true),
      '출발지를 인식하지 못했습니다. 출발지를 입력해주세요.',
    );
    expect(
      routeSearchNotice(from: true, to: false),
      '도착지를 인식하지 못했습니다. 도착지를 입력해주세요.',
    );
    expect(
      routeSearchNotice(from: false, to: false),
      startsWith('출발지·도착지를 인식하지 못했습니다.'),
    );
  });

  testWidgets('홈 안내는 5초 보이고, 새 안내가 오면 이전 것을 바로 바꾼다', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [HomeToast()])),
        ),
      ),
    );
    final notices = container.read(homeNoticeProvider.notifier);

    notices.show('출발지를 인식하지 못했습니다. 출발지를 입력해주세요.');
    await tester.pump();
    expect(find.textContaining('출발지를 인식'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    notices.show('경로 설정이 완료되었습니다.');
    await tester.pump();
    // The shared toast cross-fades for 200ms
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('출발지를 인식'), findsNothing);
    expect(find.text('경로 설정이 완료되었습니다.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('경로 설정이 완료되었습니다.'), findsOneWidget, reason: 'restarted');
    await tester.pump(HomeToast.duration);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('경로 설정이 완료되었습니다.'), findsNothing);
  });
}
