import '../campus_map.dart';
import '../campus_map_repository.dart';
import 'pano_spots_mock.dart';
import 'search_places_mock.dart';

// Bundled spots and places; the bundled links are already in the graph
class MockCampusMapRepository implements CampusMapRepository {
  const MockCampusMapRepository();

  @override
  Future<CampusMap> load() async =>
      const CampusMap(spots: panoSpots, links: [], places: searchPlaces);
}
