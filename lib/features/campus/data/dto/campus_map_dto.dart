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
      final spot = NodeDto.fromJson(node).toModel();
      if (spot == null) continue;
      final photo = (node['imageUrl'] as String?)?.trim();
      spots.add(spot.withPhoto(photo == null || photo.isEmpty ? null : photo));
      places.addAll(PlaceDto.listFrom(node['places'] ?? const []));
    }
    final ids = {for (final s in spots) s.id};
    return CampusMap(
      spots: spots,
      places: places,
      links: [
        for (final item in json['edges'] as List? ?? const [])
          ?_link(item as Map<String, dynamic>, ids),
      ],
    );
  }

  // Edge between two known nodes; unknown move types walk
  static (String, RouteLink)? _link(Map<String, dynamic> e, Set<String> ids) {
    final from = e['fromNodeId'] as String?;
    final to = e['toNodeId'] as String?;
    if (from == null ||
        to == null ||
        !ids.contains(from) ||
        !ids.contains(to)) {
      return null;
    }
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
