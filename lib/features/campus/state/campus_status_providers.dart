import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/data_source.dart';
import '../data/campus_models.dart';
import '../data/campus_status_repository.dart';
import 'launch_provider.dart';

final campusStatusRepositoryProvider = Provider<CampusStatusRepository>((ref) {
  final launch = ref.watch(launchEntryProvider);
  return selectDataSource(
    ref.watch(appConfigProvider),
    mock: () => MockCampusStatusRepository(
      demoClosures: launch.demoClosures,
      wetKind: launch.wetKind,
    ),
  );
});

final campusClosuresProvider = FutureProvider<List<Closure>>(
  (ref) => ref.watch(campusStatusRepositoryProvider).closures(),
);

final campusWeatherProvider = FutureProvider<CampusWeather>(
  (ref) => ref.watch(campusStatusRepositoryProvider).weather(),
);
