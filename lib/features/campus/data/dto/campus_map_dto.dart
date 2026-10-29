import '../../../navigation/data/navigation_models.dart';
import '../campus_map.dart';
import '../campus_models.dart';
import 'node_dto.dart';
import 'place_dto.dart';

// CampusMapResponseDTO: nodes with photo and places, plus directed edges
abstract final class CampusMapDto {
  static const _via = {
    'WALK': Via.walk,
    'STAIRS': Via.stairs,
    'ELEVATOR': Via.elevator,
    'DOOR': Via.door,
  };

  static CampusMap fromJson(Object? data) {
    final json = data! as Map<String, dynamic>;
    final spots = <PanoSpot>[];
    final places = <SearchPlace>[];
    for (final item in json['nodes'] as List? ?? const []) {
      final node = item as Map<String, dynamic>;
      final spot = spotFrom(node);
      if (spot == null) continue;
      spots.add(spot);
      places.addAll(PlaceDto.listFrom(node['places'] ?? const []));
    }
    final ids = {for (final s in spots) s.id};
    return CampusMap(
      spots: spots,
      places: places,
      links: [
        for (final item in json['edges'] as List? ?? const [])
          if (edgeFrom(item as Map<String, dynamic>) case final e?
              when ids.contains(e.$1) && ids.contains(e.$2.to))
            e,
      ],
    );
  }

  // Node with its photo URL, or null without an id or a title
  static PanoSpot? spotFrom(Map<String, dynamic> node) {
    final spot = NodeDto.fromJson(node).toModel();
    final photo = (node['imageUrl'] as String?)?.trim();
    return spot?.withPhoto(photo == null || photo.isEmpty ? null : photo);
  }

  // Directed edge or route segment; unknown move types walk
  static (String, RouteLink)? edgeFrom(Map<String, dynamic> e) {
    final from = e['fromNodeId'] as String?;
    final to = e['toNodeId'] as String?;
    if (from == null || to == null || from.isEmpty || to.isEmpty) return null;
    final note = (e['description'] as String?)?.trim();
    return (
      from,
      RouteLink(
        to: to,
        via: _via[e['moveType']] ?? Via.walk,
        note: note == null || note.isEmpty ? null : note,
        fromServer: true,
      ),
    );
  }
}
