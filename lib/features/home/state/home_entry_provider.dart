import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router.dart';
import '../../splash/data/nfc_places_mock.dart';
import '../data/campus_buildings_mock.dart';
import '../data/campus_models.dart';
import '../data/home_mock.dart';

// Launch link query (?from=, ?to=, ?weather=rain, ?closures=demo)
final homeLaunchQueryProvider = Provider<Map<String, String>>((ref) {
  return ref
      .watch(routerProvider)
      .routeInformationProvider
      .value
      .uri
      .queryParameters;
});

final campusWeatherProvider = Provider<CampusWeather>((ref) {
  final kind = ref.watch(homeLaunchQueryProvider)['weather'];
  return CampusWeather(
    wetKind: WetKind.values.where((k) => k.name == kind).firstOrNull,
  );
});

final campusClosuresProvider = Provider<List<Closure>>((ref) {
  final demo = ref.watch(homeLaunchQueryProvider)['closures'] == 'demo';
  return demo ? demoClosures : const [];
});

// Resolve a shared or NFC place id into a selectable place
CampusPlace? placeFromId(String? id) {
  if (id == null) return null;
  final nfc = nfcPlaceNames[id];
  if (nfc != null) return CampusPlace(id: id, name: nfc);
  for (final b in campusBuildings) {
    if (b.main.id == id) return b.main;
    for (final p in b.places) {
      if (p.id == id) return p;
    }
  }
  for (final q in quickPlaces) {
    if (q.place.id == id) return q.place;
  }
  return null;
}
