import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/data_source.dart';
import '../../../core/network/dio_provider.dart';
import '../data/api_node_repository.dart';
import '../data/campus_directory.dart';
import '../data/campus_models.dart';
import '../data/mock/mock_node_repository.dart';
import '../data/node_repository.dart';

final nodeRepositoryProvider = Provider<NodeRepository>(
  (ref) => selectDataSource(
    ref.watch(appConfigProvider),
    mock: MockNodeRepository.new,
    api: () => ApiNodeRepository(ref.watch(apiClientProvider)),
  ),
);

// Every photo spot, merged into the map data once; Dio already retries
final nodeCatalogProvider = FutureProvider<List<PanoSpot>>((ref) async {
  final spots = await ref.watch(nodeRepositoryProvider).all();
  registerSpots(spots);
  return spots;
}, retry: (_, _) => null);
