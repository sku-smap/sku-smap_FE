import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/recent_places_storage.dart';

final recentPlacesStorageProvider = Provider<RecentPlacesStorage>(
  (ref) => const RecentPlacesStorage(),
);

// Recent destination ids, newest first, kept on the device
class RecentPlacesController extends Notifier<List<String>> {
  static const max = 8;

  RecentPlacesStorage get _storage => ref.read(recentPlacesStorageProvider);

  @override
  List<String> build() {
    // Picks made before the saved list loads stay in front
    _storage.load().then((saved) {
      if (!ref.mounted) return;
      state = _merge(state, saved);
    });
    return const [];
  }

  void add(String id) {
    state = _merge([id], state);
    _storage.save(state);
  }

  static List<String> _merge(List<String> first, List<String> rest) =>
      {...first, ...rest}.take(max).toList();
}

final recentPlacesProvider =
    NotifierProvider<RecentPlacesController, List<String>>(
      RecentPlacesController.new,
    );
