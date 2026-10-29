import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import 'navigation_models.dart';
import 'route_graph.dart';
import 'route_plan.dart';
import 'route_repository.dart';

// Bundled graph search; walks around closed spots like the server should
class MockRouteRepository implements RouteRepository {
  const MockRouteRepository({required this.blocked});

  final Set<String> Function() blocked;

  @override
  Future<RoutePlan?> find({
    required String from,
    required String to,
    required RouteOption option,
  }) async {
    final path = findRoute(
      from,
      to,
      mode: option == RouteOption.comfortable
          ? RouteMode.elevator
          : RouteMode.outdoor,
      indoor: option == RouteOption.indoorUndergroundFirst,
      blocked: blocked(),
    );
    if (path == null) return null;
    return RoutePlan(
      path: path,
      legs: [
        for (var i = 1; i < path.length; i++)
          edgeBetween(path[i - 1], path[i]) ??
              RouteLink(
                to: path[i],
                via: spotById[path[i - 1]]?.floor == spotById[path[i]]?.floor
                    ? Via.walk
                    : Via.elevator,
              ),
      ],
    );
  }
}
