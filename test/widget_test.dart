import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/app.dart';
import 'package:smap/core/widgets/placeholder_page.dart';

void main() {
  testWidgets('루트 라우트가 렌더된다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmapApp()));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderPage), findsOneWidget);
  });
}
