import 'package:flutter_test/flutter_test.dart';
import 'package:smap/features/campus/data/campus_directory.dart';
import 'package:smap/features/campus/data/campus_models.dart';
import 'package:smap/features/campus/data/dto/node_dto.dart';
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

// GET /api/v1/buildings id → display name, from the backend spec
const _serverBuildings = {
  'BON': '본관',
  'BUKAK': '북악관',
  'CHUNGWOON': '청운관',
  'DAEIL': '대일관',
  'EUNJU1': '은주1관',
  'EUNJU2': '은주2관',
  'HYEIN': '혜인관',
  'HANLIM': '한림관',
  'MOONYE': '문예관',
  'SANGSEUNG': '상승관',
  'YUDAM': '유담관',
  'SUIN': '수인관',
  'MOONYE_BUKAK_CONNECTOR': '문예관-북악관 연결구간',
};

void main() {
  group('건물 이름 매핑', () {
    test('서버 건물 ID는 같은 이름의 앱 건물로 이어진다', () {
      for (final MapEntry(key: id, value: name) in _serverBuildings.entries) {
        final spot = NodeDto.fromJson({
          'nodeId': 'n',
          'title': 't',
          'buildingId': id,
          'building': name,
        }).toModel()!;
        expect(buildingNameOf(spot.building), name, reason: id);
      }
      for (final id in [
        'OUTDOOR_GROUND',
        'OUTDOOR_UNDERGROUND',
        'OUTDOOR_UNKNOWN',
      ]) {
        final spot = NodeDto.fromJson({
          'nodeId': 'n',
          'title': 't',
          'buildingId': id,
          'building': '야외',
        }).toModel()!;
        expect(spot.outdoor, isTrue, reason: id);
      }
    });

    test('홈 지도 건물과 층 안내도 이름표가 같은 이름을 쓴다', () {
      for (final b in campusBuildings) {
        expect(buildingNames[b.id], b.name, reason: b.id);
      }
    });

    test('사진 위 이름표에 빈칸 표시가 없고 건물 이름은 실제 건물이다', () {
      final names = {...buildingNames.values};
      for (final MapEntry(key: spot, value: marks) in panoMarks.entries) {
        for (final m in marks) {
          expect(m.title.trim(), isNotEmpty, reason: spot);
          expect(m.title, isNot('이름 입력'), reason: spot);
          if (m.label && RegExp(r'^\S+관$').hasMatch(m.title)) {
            expect(names, contains(m.title), reason: '$spot ${m.title}');
          }
        }
      }
    });
  });

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
