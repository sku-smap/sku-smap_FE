import '../../campus/data/campus_models.dart';
import 'route_plan.dart';

// Route between two photo spots; null when no way connects them
abstract interface class RouteRepository {
  Future<RoutePlan?> find({
    required String from,
    required String to,
    required RouteOption option,
  });
}
