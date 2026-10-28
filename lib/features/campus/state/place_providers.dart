import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/data_source.dart';
import '../../../core/network/dio_provider.dart';
import '../data/api_place_repository.dart';
import '../data/campus_directory.dart';
import '../data/campus_models.dart';
import '../data/mock/mock_place_repository.dart';
import '../data/place_repository.dart';

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => selectDataSource(
    ref.watch(appConfigProvider),
    mock: MockPlaceRepository.new,
    api: () => ApiPlaceRepository(ref.watch(apiClientProvider)),
  ),
);

// Every campus place, loaded once and kept resolvable by id; Dio already
// retries, so a failure shows at once for the user to retry
final placeCatalogProvider = FutureProvider<List<SearchPlace>>((ref) async {
  final places = await ref.watch(placeRepositoryProvider).all();
  registerPlaces(places);
  return places;
}, retry: (_, _) => null);

// Search start list; the server has no popular flag yet
const popularPlaceIds = [
  'f-bus',
  'b-bonkwan',
  'b-yudam',
  'f-cafeteria',
  'f-gate',
  'b-bukak',
  'f-parking1',
  'b-hyein',
];

final popularPlacesProvider = Provider<AsyncValue<List<SearchPlace>>>((ref) {
  return ref.watch(placeCatalogProvider).whenData((places) {
    final byId = {for (final p in places) p.id: p};
    return [for (final id in popularPlaceIds) ?byId[id]];
  });
});
