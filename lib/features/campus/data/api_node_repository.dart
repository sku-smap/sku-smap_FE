import '../../../core/network/api_client.dart';
import 'campus_models.dart';
import 'dto/node_dto.dart';
import 'node_repository.dart';

class ApiNodeRepository implements NodeRepository {
  const ApiNodeRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<PanoSpot>> all() =>
      _api.get('/api/v1/nodes', decode: NodeDto.listFrom);
}
