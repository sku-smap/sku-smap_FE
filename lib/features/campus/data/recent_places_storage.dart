import 'package:shared_preferences/shared_preferences.dart';

// Destinations picked on this device, newest first; no login, so per device
class RecentPlacesStorage {
  const RecentPlacesStorage();

  static const _key = 'smap.recentDestinations';

  // Best effort: private browsing, blocked or missing storage means no history
  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, ids);
    } catch (_) {
      return;
    }
  }
}
