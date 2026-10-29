import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smap/app.dart';
import 'package:smap/core/router.dart';
import 'package:smap/core/widgets/placeholder_page.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_map.dart';
import 'package:smap/features/campus/data/campus_map_repository.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/state/launch_provider.dart';
import 'package:smap/features/campus/state/nfc_link_provider.dart';
import 'package:smap/features/campus/state/node_providers.dart';
import 'package:smap/features/campus/state/trip_controller.dart';
import 'package:smap/features/home/presentation/widgets/nfc_notice.dart';
import 'package:smap/features/report/presentation/widgets/applied_notice.dart';
import 'package:smap/features/splash/state/splash_entry_provider.dart';

class _Map implements CampusMapRepository {
  const _Map();

  @override
  Future<CampusMap> load() async => const CampusMap(
    spots: [PanoSpot(id: 'EJ9_01', title: '은주9관 입구', building: 'outdoor')],
    links: [],
    places: [],
  );
}

ProviderContainer _container(
  Map<String, String> launch, {
  CampusMapRepository? map,
}) {
  final c = ProviderContainer(
    overrides: [
      launchQueryProvider.overrideWithValue(launch),
      if (map != null) campusMapRepositoryProvider.overrideWithValue(map),
    ],
  );
  addTearDown(c.dispose);
  c.listen(tripProvider, (_, _) {});
  c.listen(nfcNoticeProvider, (_, _) {});
  return c;
}

void main() {
  tearDown(() {
    resetSpots();
    resetPlaces();
  });

  test('src=nfc의 from만 태그 위치로 읽는다', () {
    expect(nfcIdOf(const {'src': 'nfc', 'from': ' gate_front '}), 'gate_front');
    expect(nfcIdOf(const {'src': 'nfc', 'from': ''}), isNull);
    expect(nfcIdOf(const {'src': 'nfc'}), isNull);
    expect(nfcIdOf(const {'from': 'gate_front'}), isNull);
  });

  test('노드 ID 태그는 그 지점을 출발지로, 스플래시에 같은 이름을 보인다', () {
    final c = _container(const {'src': 'nfc', 'from': 'gate_front'});
    final from = c.read(tripProvider).from!;
    expect(from.id, 'gate_front');
    expect(from.name, spotById['gate_front']!.title);
    expect(c.read(splashNfcPlaceProvider), from.name);
    expect(c.read(nfcNoticeProvider), isNull, reason: 'the splash says it');
  });

  test('서버에만 있는 노드 ID는 지도 데이터가 오면 출발지가 된다', () async {
    final c = _container(const {
      'src': 'nfc',
      'from': 'EJ9_01',
    }, map: const _Map());
    expect(c.read(tripProvider).from, isNull);
    await c.read(nodeCatalogProvider.future);
    await pumpEventQueue();
    expect(c.read(tripProvider).from?.name, '은주9관 입구');
    expect(c.read(nfcNoticeProvider), isNull);
  });

  test('없는 지점이면 출발지를 비우고 목록이 온 뒤 안내한다', () async {
    final c = _container(const {'src': 'nfc', 'from': 'nope'});
    expect(c.read(splashNfcPlaceProvider), isNull);
    await c.read(nodeCatalogProvider.future);
    await pumpEventQueue();
    expect(c.read(tripProvider).from, isNull);
    expect(c.read(nfcNoticeProvider)?.text, nfcUnknown);
  });

  test('실행 중에 태그하면 출발지를 바꾸고, 같은 태그도 다시 알린다', () {
    final c = _container(const {});
    final links = c.read(nfcLinkProvider.notifier);
    c
        .read(tripProvider.notifier)
        .setFrom(const CampusPlace(id: 'b-bonkwan', name: '본관'));

    links.receive(Uri.parse('/navigation?from=gate_front&to=b-bonkwan'));
    expect(
      c.read(nfcLinkProvider),
      isNull,
      reason: 'in-app routes are not tags',
    );

    links.receive(Uri.parse('/?src=nfc&from=bus_stop'));
    expect(c.read(tripProvider).from?.name, '버스정류장');
    expect(c.read(nfcNoticeProvider)?.text, '지금 계신 버스정류장에서 시작할게요');

    c
        .read(tripProvider.notifier)
        .setFrom(const CampusPlace(id: 'b-bonkwan', name: '본관'));
    links.receive(Uri.parse('/?src=nfc&from=bus_stop'));
    expect(c.read(tripProvider).from?.id, 'bus_stop');
    expect(c.read(nfcNoticeProvider)?.seq, 2);
  });

  testWidgets('앱 실행 중 들어온 태그 링크를 받아 출발지로 정한다', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, _) => const PlaceholderPage(title: '홈'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const SmapApp(),
      ),
    );
    await tester.pumpAndSettle();

    await router.routeInformationProvider.didPushRouteInformation(
      RouteInformation(uri: Uri.parse('/?src=nfc&from=bus_stop')),
    );
    await tester.pump();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(PlaceholderPage)),
    );
    expect(c.read(tripProvider).from?.id, 'bus_stop');
  });

  testWidgets('없는 지점 태그는 스플래시가 끝난 뒤 토스트로 알린다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          launchQueryProvider.overrideWithValue(const {
            'src': 'nfc',
            'from': 'nope',
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [NfcNotice()])),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(nfcUnknown), findsNothing);

    await tester.pump(ReportAppliedNotice.delay);
    expect(find.text(nfcUnknown), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
