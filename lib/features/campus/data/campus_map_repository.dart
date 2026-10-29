import 'campus_map.dart';

// Photo spots, their links and places for street view and the map
abstract interface class CampusMapRepository {
  Future<CampusMap> load();
}
