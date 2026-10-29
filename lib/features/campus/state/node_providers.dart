import 'dart:async';

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

// The server caches the map for 5 minutes; refresh just inside that so data
// edits and signed photo URLs (1 hour) stay current
const campusMapRefresh = Duration(minutes: 4, seconds: 30);

// One campus map load feeds spots, links and places; Dio already retries.
// Only this first load shows a loading screen
final campusMapProvider = FutureProvider<CampusMap>((ref) async {
  final map = await ref.watch(campusMapRepositoryProvider).load();
  if (map.isEmpty) throw const ServerException('지도 데이터가 비어 있어요.');
  _merge(map);
  if (!ref.read(appConfigProvider).useMock) {
    final timer = Timer.periodic(
      campusMapRefresh,
      (_) => ref.read(campusMapRefreshProvider)().ignore(),
    );
    ref.onDispose(timer.cancel);
  }
  return map;
}, retry: (_, _) => null);

void _merge(CampusMap map) {
  registerSpots(map.spots);
  registerLinks(map.links);
  registerPlaces(map.places);
}

// Silent reload merged into the registries; no provider is invalidated, so
// open screens and guidance keep their state and a failure keeps old data
final campusMapRefreshProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final map = await ref.read(campusMapRepositoryProvider).load();
    if (!map.isEmpty) _merge(map);
  },
);

// Photo spots are ready to resolve once the campus map is merged
final nodeCatalogProvider = FutureProvider<List<PanoSpot>>(
  (ref) async => (await ref.watch(campusMapProvider.future)).spots,
  retry: (_, _) => null,
);
