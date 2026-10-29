import '../../navigation/data/navigation_models.dart';
import 'campus_models.dart';

// Everything the street view needs from GET /api/v1/campus-map
class CampusMap {
  const CampusMap({
    required this.spots,
    required this.links,
    required this.places,
  });

  final List<PanoSpot> spots;
  final List<(String from, RouteLink link)> links;
  final List<SearchPlace> places;

  bool get isEmpty => spots.isEmpty;
}
