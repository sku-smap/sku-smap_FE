import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/data_source.dart';
import '../../../core/network/dio_provider.dart';
import '../../navigation/data/route_graph.dart';
import '../data/api_campus_map_repository.dart';
import '../data/campus_directory.dart';
import '../data/campus_map.dart';
import '../data/campus_map_repository.dart';
import '../data/campus_models.dart';
import '../data/mock/mock_campus_map_repository.dart';

final campusMapRepositoryProvider = Provider<CampusMapRepository>(
  (ref) => selectDataSource(
    ref.watch(appConfigProvider),
    mock: MockCampusMapRepository.new,
    api: () => ApiCampusMapRepository(ref.watch(apiClientProvider)),
  ),
);

// One campus map load feeds spots, links and places; Dio already retries
final campusMapProvider = FutureProvider<CampusMap>((ref) async {
  final map = await ref.watch(campusMapRepositoryProvider).load();
  if (map.isEmpty) throw const ServerException('지도 데이터가 비어 있어요.');
  registerSpots(map.spots);
  registerLinks(map.links);
  registerPlaces(map.places);
  return map;
}, retry: (_, _) => null);

// Photo spots are ready to resolve once the campus map is merged
final nodeCatalogProvider = FutureProvider<List<PanoSpot>>(
  (ref) async => (await ref.watch(campusMapProvider.future)).spots,
  retry: (_, _) => null,
);
