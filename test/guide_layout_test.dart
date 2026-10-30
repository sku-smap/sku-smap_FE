import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/home/presentation/widgets/route_card.dart';
import 'package:smap/features/navigation/data/navigation_models.dart';
import 'package:smap/features/navigation/presentation/navigation_tokens.dart';
import 'package:smap/features/navigation/presentation/widgets/floor_bar.dart';
import 'package:smap/features/navigation/presentation/widgets/marquee_text.dart';
import 'package:smap/features/navigation/presentation/widgets/step_card.dart';
import 'package:smap/features/navigation/state/navigation_controller.dart';

Widget _host(Widget child, {double width = 370, bool still = false}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: still,
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );

double _shift(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(
        of: find.byType(MarqueeText),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .getTranslation()
    .x;

const _long = '폭풍의언덕 문예관 3갈래 방향으로 아주 길게 이동하세요 정말 길게';

NavigationState _guide({String? note, bool arrived = false}) {
  const path = ['gate_front', 'parking_3way'];
  return NavigationState(
    route: ActiveRoute(
      from: const RouteEnd(id: 'gate_front', node: 'gate_front', label: '정문'),
      to: const RouteEnd(id: 'b-bonkwan', node: 'parking_3way', label: '본관'),
      path: path,
      legs: [RouteLink(to: 'parking_3way', via: Via.walk, note: note)],
    ),
    node: arrived ? path.last : path.first,
  );
}

Widget _card(NavigationState state) => StepCard(
  state: state,
  onToggleMute: () {},
  onShowSteps: () {},
  onShare: () {},
  onNavigate: (_) {},
  onExit: () {},
  onReport: ({kind}) {},
  onPraise: () {},
);

void main() {
  group('전광판 글자', () {
    testWidgets('짧으면 그대로, 길면 왼쪽으로 흐르며 반복한다', (tester) async {
      await tester.pumpWidget(
        _host(MarqueeText('짧은 안내', style: NavText.stepText)),
      );
      expect(
        find.descendant(
          of: find.byType(MarqueeText),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );

      await tester.pumpWidget(
        _host(MarqueeText(_long, style: NavText.stepText), width: 200),
      );
      await tester.pump();
      expect(_shift(tester), 0);
      await tester.pump(MarqueeText.pause + const Duration(seconds: 2));
      expect(_shift(tester), lessThan(0));
      expect(find.text(_long), findsOneWidget, reason: 'one readable copy');
    });

    testWidgets('움직임 줄이기 설정이면 흐르지 않고 말줄임으로 둔다', (tester) async {
      await tester.pumpWidget(
        _host(
          MarqueeText(_long, style: NavText.stepText),
          width: 200,
          still: true,
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(
        find.descendant(
          of: find.byType(MarqueeText),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
    });
  });

  testWidgets('안내판은 문구가 있든 없든, 도착해도 높이가 같다', (tester) async {
    Future<double> heightOf(NavigationState s) async {
      await tester.pumpWidget(_host(_card(s)));
      await tester.pump();
      return tester.getSize(find.byType(StepCard)).height;
    }

    final withNote = await heightOf(_guide(note: _long));
    expect(await heightOf(_guide()), withNote);
    expect(await heightOf(_guide(arrived: true)), withNote);
    expect(find.text('안내가 정확했나요?'), findsOneWidget);
  });

  testWidgets('층 버튼은 다섯 개까지 보이고 현재 층이 보이게 스크롤된다', (tester) async {
    final floors = [
      for (var i = 1; i <= 9; i++)
        FloorStop(floor: '$i층', label: '${i}F', node: 'n$i'),
    ];
    await tester.pumpWidget(
      _host(
        FloorBar(
          building: '유담관',
          current: '2층',
          floors: floors,
          onFloor: (_) {},
        ),
        width: 52,
      ),
    );
    final scroll = tester.getSize(find.byType(SingleChildScrollView));
    expect(scroll.height, 5 * 32 + 4 * 3);
    expect(tester.getRect(find.text('2F')).bottom, lessThan(844));
    final view = tester.getRect(find.byType(SingleChildScrollView));
    expect(view.contains(tester.getCenter(find.text('2F'))), isTrue);
  });

  testWidgets('실내·지하 길을 켜면 이동 방식 선택이 숨는다', (tester) async {
    Widget card(bool indoor) => _host(
      RouteCard(
        trip: TripState(indoor: indoor),
        weather: const CampusWeather(),
        onPickFrom: () {},
        onPickTo: () {},
        onSwap: () {},
        onMode: (_) {},
        onGo: () {},
        onIndoor: () {},
      ),
      width: 350,
    );
    await tester.pumpWidget(card(false));
    expect(find.text('편한길'), findsOneWidget);
    await tester.pumpWidget(card(true));
    expect(find.text('편한길'), findsNothing);
    expect(find.text('길찾기'), findsOneWidget);
  });
}
