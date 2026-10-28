import '../campus_models.dart';
import '../node_repository.dart';
import 'pano_spots_mock.dart';

// Bundled photo spots until USE_MOCK is off
class MockNodeRepository implements NodeRepository {
  const MockNodeRepository();

  @override
  Future<List<PanoSpot>> all() async => panoSpots;
}
