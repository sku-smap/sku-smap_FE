import 'campus_models.dart';
import 'mock/campus_status_mock.dart';

// Live campus conditions the server and weather API will provide
abstract interface class CampusStatusRepository {
  Future<List<Closure>> closures();

  Future<CampusWeather> weather();
}

// Launch link flags stand in for the server (?closures=demo, ?weather=rain)
class MockCampusStatusRepository implements CampusStatusRepository {
  const MockCampusStatusRepository({this.demoClosures = false, this.wetKind});

  final bool demoClosures;
  final WetKind? wetKind;

  @override
  Future<List<Closure>> closures() async =>
      demoClosures ? demoClosuresMock : const [];

  @override
  Future<CampusWeather> weather() async => CampusWeather(wetKind: wetKind);
}
