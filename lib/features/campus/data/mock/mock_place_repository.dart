import '../../../search/data/place_search.dart';
import '../campus_models.dart';
import '../place_repository.dart';
import 'search_places_mock.dart';

// Bundled places and the local search rules until USE_MOCK is off
class MockPlaceRepository implements PlaceRepository {
  const MockPlaceRepository({this.delay = Duration.zero});

  final Duration delay;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<SearchPlace>> all() async {
    await _wait();
    return searchPlaces;
  }

  @override
  Future<List<SearchPlace>> search(String keyword) async {
    await _wait();
    return searchPlacesFor(keyword, limit: 12);
  }
}
