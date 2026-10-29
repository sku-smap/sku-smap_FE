import '../../../core/network/api_client.dart';
import '../../../core/network/app_exception.dart';
import '../../campus/data/campus_models.dart';
import 'dto/route_dto.dart';
import 'route_plan.dart';
import 'route_repository.dart';

class ApiRouteRepository implements RouteRepository {
  const ApiRouteRepository(this._api);

  final ApiClient _api;

  @override
  Future<RoutePlan?> find({
    required String from,
    required String to,
    required RouteOption option,
  }) async {
    try {
      return await _api.post(
        '/api/v1/routes',
        body: {
          'fromNodeId': from,
          'toNodeId': to,
          'option': RouteDto.optionName(option),
        },
        decode: (data) => RouteDto.planFrom(data, from: from, to: to),
      );
    } on ServerException catch (e) {
      // The server answers an unreachable goal with 404
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
