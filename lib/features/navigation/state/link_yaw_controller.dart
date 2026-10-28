import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_config.dart';
import '../../../core/network/data_source.dart';
import '../data/link_yaw_repository.dart';
import '../data/route_graph.dart';

final linkYawRepositoryProvider = Provider<LinkYawRepository>(
  (ref) => selectDataSource(
    ref.watch(appConfigProvider),
    mock: MockLinkYawRepository.new,
  ),
);

// Saved arrow directions layered over the bundled ones
class LinkYawController extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() =>
      ref.watch(linkYawRepositoryProvider).load();

  // Point the arrow from one spot to the next at a photo direction
  Future<void> fix(String from, String to, double yaw) async {
    final key = linkYawKey(from, to);
    final degrees = (yaw % 360 + 360) % 360;
    state = AsyncData({...?state.value, key: degrees});
    await ref.read(linkYawRepositoryProvider).save(key, degrees);
  }
}

final linkYawProvider =
    AsyncNotifierProvider<LinkYawController, Map<String, double>>(
      LinkYawController.new,
    );
