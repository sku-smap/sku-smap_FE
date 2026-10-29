import 'package:flutter/foundation.dart';

import 'campus_models.dart';
import 'mock/campus_buildings_mock.dart';
import 'mock/campus_floors_mock.dart';
import 'mock/nfc_places_mock.dart';
import 'mock/pano_spots_mock.dart';
import 'mock/search_places_mock.dart';

// Bundled places until the server list arrives; server entries win by id
final Map<String, SearchPlace> placeById = {
  for (final p in searchPlaces) p.id: p,
};

// Keep server places resolvable by id for links, trips and guidance
void registerPlaces(Iterable<SearchPlace> places) {
  for (final p in places) {
    placeById[p.id] = p;
  }
}

@visibleForTesting
void resetPlaces() => placeById
  ..clear()
  ..addAll({for (final p in searchPlaces) p.id: p});

@visibleForTesting
void resetSpots() => spotById
  ..clear()
  ..addAll({for (final n in panoSpots) n.id: n});

// Bundled photo spots until the server list arrives; see [registerSpots]
final Map<String, PanoSpot> spotById = {for (final n in panoSpots) n.id: n};

// Merge server nodes: known ids keep their map data, new ids join without it
void registerSpots(Iterable<PanoSpot> spots) {
  for (final s in spots) {
    spotById[s.id] = spotById[s.id]?.withServer(s) ?? s;
  }
}

// Display name for a building key; server-only buildings use their name
String buildingNameOf(String key) => buildingNames[key] ?? key;

final buildingById = {for (final b in campusBuildings) b.id: b};

// Resolve a shared, NFC, search or 360 spot id into a selectable place
CampusPlace? resolvePlace(String? id) {
  if (id == null) return null;
  final nfc = nfcPlaceNames[id];
  if (nfc != null) return CampusPlace(id: id, name: nfc);
  final place = placeById[id];
  if (place != null) return place.spot;
  if (id.startsWith('b-')) return buildingById[id.substring(2)]?.main;
  return spotById[id]?.spot;
}

// The 360 spot a place id stands for
String? nodeOf(String? id) => placeById[id]?.node ?? spotById[id]?.id;

// Nearest 360 spot to a map point (percent) on the same level
PanoSpot? nearestSpot(double x, double y, [MapLevel level = MapLevel.ground]) {
  PanoSpot? best;
  var bestDistance = double.infinity;
  for (final n in spotById.values) {
    final nx = n.x;
    final ny = n.y;
    if (nx == null || ny == null || n.level != level || n.flat || n.hidden) {
      continue;
    }
    final d = (nx - x) * (nx - x) + (ny - y) * (ny - y);
    if (d < bestDistance) {
      bestDistance = d;
      best = n;
    }
  }
  return best;
}
