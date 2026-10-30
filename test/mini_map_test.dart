import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/navigation/presentation/widgets/mini_map.dart';

Future<void> _pump(WidgetTester tester, PanoSpot here) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 180,
        child: MiniMap(
          here: here,
          route: null,
          showMap: true,
          onFloorSheet: () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('좌표 없는 서버 지점은 그 건물 핀 위치를 강조한다', (tester) async {
    await _pump(
      tester,
      const PanoSpot(
        id: 'CW05_C',
        title: '청운관 1층',
        building: 'chungwoon',
        floor: '1층',
      ),
    );
    expect(find.bySemanticsLabel('현재 건물'), findsOneWidget);
    expect(find.text('지도 위치 준비 중'), findsNothing);
  });

  testWidgets('건물을 모르는 야외 서버 지점은 준비 중으로 둔다', (tester) async {
    await _pump(
      tester,
      const PanoSpot(id: 'OUT_9', title: '야외 9', building: 'outdoor'),
    );
    expect(find.bySemanticsLabel('현재 건물'), findsNothing);
    expect(find.text('지도 위치 준비 중'), findsOneWidget);
  });

  testWidgets('좌표가 있는 지점은 그 자리에 점을 찍는다', (tester) async {
    await _pump(
      tester,
      const PanoSpot(id: 'p', title: '정문', building: 'outdoor', x: 50, y: 50),
    );
    expect(find.bySemanticsLabel('현재 건물'), findsNothing);
    expect(find.text('지도 위치 준비 중'), findsNothing);
  });
}
