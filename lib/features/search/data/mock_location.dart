import '../../home/data/campus_models.dart';
import 'pano_spots_mock.dart';
import 'search_models.dart';

enum LocateError {
  unavailable('위치를 찾지 못했어요. 실내라면 검색이나 지도에서 골라주세요.'),
  outside('지금 학교 밖이에요. 학교에 오면 쓸 수 있어요 — 정문에서 출발하려면 아래에서 ‘정문’을 고르세요.');

  const LocateError(this.message);

  final String message;
}

typedef LocateResult = ({CampusPlace? spot, LocateError? error});

// Nearest 360 spot to a map point (percent) on the same level
PanoSpot? nearestSpot(double x, double y, [MapLevel level = MapLevel.ground]) {
  PanoSpot? best;
  var bestDistance = double.infinity;
  for (final n in panoSpots) {
    if (n.level != level || n.flat || n.hidden) continue;
    final d = (n.x - x) * (n.x - x) + (n.y - y) * (n.y - y);
    if (d < bestDistance) {
      bestDistance = d;
      best = n;
    }
  }
  return best;
}

class MockLocator {
  const MockLocator({required this.onCampus});

  // Campus reference point (37.615065, 127.012854) projected onto the map
  static const _campusX = 53.4167;
  static const _campusY = 38.5;

  final bool onCampus;

  Future<LocateResult> locate() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!onCampus) return (spot: null, error: LocateError.outside);
    final n = nearestSpot(_campusX, _campusY);
    if (n == null) return (spot: null, error: LocateError.unavailable);
    return (
      spot: CampusPlace(id: n.id, name: '현재 위치 · ${n.title}'),
      error: null,
    );
  }
}
