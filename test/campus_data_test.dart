import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/mock/campus_buildings_mock.dart';
import 'package:smap/features/campus/data/mock/campus_facilities_mock.dart';
import 'package:smap/features/campus/data/mock/campus_floors_mock.dart';
import 'package:smap/features/campus/data/mock/campus_status_mock.dart';
import 'package:smap/features/campus/data/mock/route_graph_mock.dart';
import 'package:smap/features/campus/data/mock/search_places_mock.dart';
import 'package:smap/features/home/data/home_mock.dart';
import 'package:smap/features/navigation/data/route_graph.dart';
import 'package:smap/features/report/data/report_mock.dart';

// Every place a home chip, building sheet or facility pin can choose
List<CampusPlace> _homePlaces() => [
  for (final q in quickPlaces) q.place,
  for (final b in campusBuildings) ...[b.main, ...b.places],
  for (final f in campusFacilities) ...f.places,
];

void main() {
  group('공통 ID', () {
    test('홈에서 고를 수 있는 장소는 모두 같은 ID 체계로 찾아진다', () {
      final missing = [
        for (final p in _homePlaces())
          if (resolvePlace(p.id) == null || nodeOf(p.id) == null) p.id,
      ];
      expect(missing, isEmpty);
    });

    test('검색 장소·층 안내·통행 불가·제보 위치가 모두 촬영 지점을 가리킨다', () {
      final nodes = [
        for (final p in searchPlaces) p.node,
        for (final stops in floorStops.values) ...stops.map((s) => s.node),
        for (final c in demoClosuresMock) c.node,
        for (final r in demoServerReports)
          if (r.node != 'home') r.node,
      ];
      expect(nodes.where((n) => spotById[n] == null), isEmpty);
    });

    test('경로 그래프의 모든 연결이 촬영 지점을 가리킨다', () {
      final ids = {
        ...routeLinks.keys,
        for (final links in routeLinks.values) ...links.map((l) => l.to),
      };
      expect(ids.where((id) => spotById[id] == null), isEmpty);
    });

    test('통행 불가 카드 문구는 그 지점 이름과 같다', () {
      for (final c in demoClosuresMock) {
        expect(c.place, spotById[c.node]!.title);
      }
    });

    test('NFC·공유 링크 ID를 장소로 바꾼다', () {
      expect(resolvePlace('bus_stop')?.name, '버스정류장');
      expect(resolvePlace('b-bonkwan')?.name, '본관');
      expect(resolvePlace('gate_front')?.name, '정문 앞');
      expect(resolvePlace('nope'), isNull);
      expect(resolvePlace(null), isNull);
    });
  });

  test('홈에서 고를 수 있는 모든 장소로 정문에서 길이 이어진다 (혜인관 제외)', () {
    final unreachable = [
      for (final p in _homePlaces())
        if (findRoute('gate_front', nodeOf(p.id)!) == null) p.id,
    ];
    // Hyein Hall's photos have no link to the outside yet
    final known = unreachable.where(
      (id) => spotById[nodeOf(id)]?.building == 'hyein',
    );
    expect(known, isNotEmpty);
    expect(unreachable.toSet().difference(known.toSet()), isEmpty);
  });
}
