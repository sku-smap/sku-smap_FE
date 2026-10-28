// Arrow direction fixes the team saves without a redeploy (A-01)
abstract interface class LinkYawRepository {
  Future<Map<String, double>> load();

  Future<void> save(String key, double yaw);
}

// Keeps fixes in memory until the server endpoint exists
class MockLinkYawRepository implements LinkYawRepository {
  final _saved = <String, double>{};

  @override
  Future<Map<String, double>> load() async => {..._saved};

  @override
  Future<void> save(String key, double yaw) async => _saved[key] = yaw;
}
