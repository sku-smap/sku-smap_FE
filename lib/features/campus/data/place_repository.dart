import 'campus_models.dart';

// Campus places for search, start picking and report locations
abstract interface class PlaceRepository {
  Future<List<SearchPlace>> all();

  // Partial match on name, alias, building and room
  Future<List<SearchPlace>> search(String keyword);
}
