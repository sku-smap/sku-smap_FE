import 'package:flutter/foundation.dart';

import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/data/mock/campus_floors_mock.dart';
import '../../campus/data/mock/route_graph_mock.dart';
import 'navigation_models.dart';

bool _hidden(String id) => spotById[id]?.hidden ?? false;

Map<String, List<RouteLink>> _bundledLinks() => {
  for (final MapEntry(:key, :value) in routeLinks.entries) key: [...value],
};

// Bundled links plus campus map edges the app did not have
final _links = _bundledLinks();

// Server edges join the graph; a known link keeps its app data but takes
// the server's arrow direction
void registerLinks(Iterable<(String from, RouteLink link)> links) {
  for (final (from, link) in links) {
    final out = _links.putIfAbsent(from, () => []);
    final i = out.indexWhere((l) => l.to == link.to);
    final yaw = link.yaw;
    if (i < 0) {
      out.add(link);
    } else if (yaw != null) {
      out[i] = out[i].withYaw(yaw);
    }
  }
}

@visibleForTesting
void resetLinks() => _links
  ..clear()
  ..addAll(_bundledLinks());

// A shared place id or a 360 spot id into a route end
RouteEnd? routeEndFor(String? id) {
  if (id == null) return null;
  final place = placeById[id];
  if (place != null) {
    return RouteEnd(
      id: id,
      node: place.node,
      label: place.name,
      sub: place.sub,
    );
  }
  final spot = spotById[id];
  return spot == null
      ? null
      : RouteEnd(id: id, node: spot.id, label: spot.title);
}

// Links from a spot, skipping hidden photos straight to the ones beyond
List<RouteLink> linksOf(String id) {
  final out = <RouteLink>[];
  final seen = {id};
  void walk(String from, [String? through, Via? via]) {
    for (final l in _links[from] ?? const <RouteLink>[]) {
      if (!seen.add(l.to)) continue;
      if (_hidden(l.to)) {
        walk(l.to, through ?? l.to, via ?? l.via);
      } else {
        out.add(through == null ? l : l.copyWith(via: via!, through: through));
      }
    }
  }

  walk(id);
  return out;
}

RouteLink? edgeBetween(String a, String b) =>
    linksOf(a).where((l) => l.to == b).firstOrNull;

// The elevator link here when the next step is several floors away
RouteLink? elevatorLinkTo(String a, String b) {
  if (edgeBetween(a, b) != null) return null;
  final building = spotById[b]?.building;
  return linksOf(a)
      .where(
        (l) => l.via == Via.elevator && spotById[l.to]?.building == building,
      )
      .firstOrNull;
}

const _outdoorPenalty = 6.0;
const _indoorPenalty = 2.5;
const _stairsPenalty = 12.0;

bool _outdoorLeg(String a, String b) =>
    spotById[a]?.outdoor == true && spotById[b]?.outdoor == true;

bool _indoorLeg(String a, String b) =>
    spotById[a]?.outdoor != true && spotById[b]?.outdoor != true;

// Dijkstra; indoor prefers covered legs, comfortable avoids stairs and
// shortest counts every link as one step like the server
List<String>? findRoute(
  String from,
  String to, {
  RouteMode mode = RouteMode.outdoor,
  bool indoor = false,
  Set<String> blocked = const {},
}) {
  if (from == to) return [from];
  final dist = <String, double>{from: 0};
  final prev = <String, String>{};
  final done = <String>{};
  while (true) {
    String? cur;
    var best = double.infinity;
    for (final e in dist.entries) {
      if (!done.contains(e.key) && e.value < best) {
        best = e.value;
        cur = e.key;
      }
    }
    if (cur == null) return null;
    if (cur == to) break;
    done.add(cur);
    for (final l in linksOf(cur)) {
      if ((blocked.contains(l.to) || blockedSpots.contains(l.to)) &&
          l.to != to) {
        continue;
      }
      final k = indoor
          ? (_outdoorLeg(cur, l.to) ? _outdoorPenalty : 1.0)
          : (mode == RouteMode.outdoor && _indoorLeg(cur, l.to)
                ? _indoorPenalty
                : 1.0);
      final stairs = mode == RouteMode.comfortable && l.via == Via.stairs
          ? _stairsPenalty
          : 1.0;
      final nd = mode == RouteMode.shortest
          ? best + 1
          : best + l.via.cost * k * stairs;
      if (nd < (dist[l.to] ?? double.infinity)) {
        dist[l.to] = nd;
        prev[l.to] = cur;
      }
    }
  }
  final path = [to];
  while (path.first != from) {
    path.insert(0, prev[path.first]!);
  }
  // Merge a multi-floor elevator ride into a single step
  return [
    for (var i = 0; i < path.length; i++)
      if (i == 0 ||
          i == path.length - 1 ||
          edgeBetween(path[i - 1], path[i])?.via != Via.elevator ||
          edgeBetween(path[i], path[i + 1])?.via != Via.elevator)
        path[i],
  ];
}

bool usesStairs(List<String> path) =>
    [for (var i = 1; i < path.length; i++) edgeBetween(path[i - 1], path[i])]
        .any((l) => l?.via == Via.stairs);

String placeLabel(PanoSpot n) =>
    [if (!n.outdoor) buildingNameOf(n.building), ?n.floor].join(' · ');

// Guidance sentence for one leg (a → b); the route's own leg wins
String instruction(String a, String b, [RouteLink? leg]) {
  final to = spotById[b]!;
  final from = spotById[a]!;
  final l = leg ?? edgeBetween(a, b);
  final floor = to.floor ?? '';
  if (l == null && from.building == to.building && from.floor != to.floor) {
    return '엘리베이터를 타고 $floor에서 내리세요';
  }
  switch (l?.via) {
    case Via.elevator:
      return '엘리베이터를 타고 ${floor.isEmpty ? '다음 층' : floor}에서 내리세요';
    case Via.stairs:
      return from.floor != null && to.floor != null && from.floor != to.floor
          ? '계단으로 ${to.floor}까지 이동하세요'
          : '계단을 따라 ${to.title}(으)로 가세요';
    case Via.passage:
      return '연결통로를 따라 ${to.title}(으)로 이동하세요';
    case Via.door:
      return '출입구를 지나 ${to.title}(으)로 들어가세요';
    default:
      return '${to.title} 방향으로 이동하세요';
  }
}

// Key of the photo arrow for a link, through any hidden photo in between
String linkYawKey(String from, String to) {
  final through = linksOf(from).where((l) => l.to == to).firstOrNull?.through;
  return '$from>${through ?? to}';
}

// Arrow direction in the photo (degrees, 0 = photo center): a team fix, then
// the server's, then the app's measured one; null means unknown, never 0
double? linkYawOf(
  String from,
  String to, [
  Map<String, double> overrides = const {},
]) {
  final through = linksOf(from).where((l) => l.to == to).firstOrNull?.through;
  if (through != null) return linkYawOf(from, through, overrides);
  final key = '$from>$to';
  final server = (_links[from] ?? const <RouteLink>[])
      .where((l) => l.to == to)
      .firstOrNull
      ?.yaw;
  return overrides[key] ?? server ?? linkYaw[key];
}

// Stairs and elevator rides on the way; the server gives no time or distance
RouteStats routeStats(List<String> path, [List<RouteLink> legs = const []]) {
  var elevators = 0;
  var stairs = 0;
  for (var i = 1; i < path.length; i++) {
    final a = spotById[path[i - 1]]!;
    final b = spotById[path[i]]!;
    final via = i <= legs.length
        ? legs[i - 1].via
        : edgeBetween(a.id, b.id)?.via;
    if (via == Via.elevator || (via == null && a.floor != b.floor)) {
      elevators++;
    } else if (via == Via.stairs) {
      stairs++;
    }
  }
  return RouteStats(elevators: elevators, stairs: stairs);
}

List<FloorStop> floorsOf(String building) =>
    building == 'outdoor' ? const [] : floorStops[building] ?? const [];

List<FloorRoom> roomsOn(String building, String floor) =>
    floorRooms['$building|$floor'] ?? const [];
