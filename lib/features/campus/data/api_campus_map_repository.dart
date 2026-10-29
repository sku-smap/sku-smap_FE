import '../../../core/network/api_client.dart';
import 'campus_map.dart';
import 'campus_map_repository.dart';
import 'dto/campus_map_dto.dart';

class ApiCampusMapRepository implements CampusMapRepository {
  const ApiCampusMapRepository(this._api);

  final ApiClient _api;

  @override
  Future<CampusMap> load() =>
      _api.get('/api/v1/campus-map', decode: CampusMapDto.fromJson);
}
