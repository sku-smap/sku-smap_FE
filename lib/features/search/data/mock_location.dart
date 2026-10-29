import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import 'location_service.dart';

// Stand-in for GPS until location is connected (?location=campus)
class MockLocator implements LocationService {
  const MockLocator({required this.onCampus});

  // Campus reference point (37.615065, 127.012854) projected onto the map
  static const _campusX = 53.4167;
  static const _campusY = 38.5;

  final bool onCampus;

  @override
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
