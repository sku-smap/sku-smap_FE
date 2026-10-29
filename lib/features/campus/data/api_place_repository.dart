import '../../../core/network/api_client.dart';
import 'campus_models.dart';
import 'dto/place_dto.dart';
import 'place_repository.dart';

class ApiPlaceRepository implements PlaceRepository {
  const ApiPlaceRepository(this._api);

  static const _path = '/api/v1/places';

  final ApiClient _api;

  @override
  Future<List<SearchPlace>> all() => _api.get(_path, decode: PlaceDto.listFrom);

  @override
  Future<List<SearchPlace>> search(String keyword) =>
      _api.get(_path, query: {'keyword': keyword}, decode: PlaceDto.listFrom);
}
