import '../../campus/data/campus_models.dart';
import 'navigation_models.dart';

// A found route: the steps to walk and what the server sent along with it
class RoutePlan {
  const RoutePlan({
    required this.path,
    required this.legs,
    this.spots = const [],
    this.links = const [],
  });

  final List<String> path;

  // legs[i] goes from path[i] to path[i + 1]
  final List<RouteLink> legs;

  // Route nodes with photos and raw segments, merged into the graph
  final List<PanoSpot> spots;
  final List<(String from, RouteLink link)> links;
}
