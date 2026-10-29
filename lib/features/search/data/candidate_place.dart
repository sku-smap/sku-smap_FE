import '../../campus/data/campus_directory.dart';
import '../../campus/data/campus_models.dart';
import '../../campus/data/dto/node_dto.dart';
import 'search_models.dart';

// A picked candidate as a trip place, resolvable later by its place or node id
CampusPlace placeOfCandidate(SearchCandidate c) {
  final placeId = c.placeId;
  if (c.type == CandidateType.place && placeId != null) {
    if (!placeById.containsKey(placeId)) {
      registerPlaces([
        SearchPlace(
          id: placeId,
          name: c.name,
          kind: c.kind,
          node: c.nodeId,
          sub: c.sub,
        ),
      ]);
    }
    return CampusPlace(id: placeId, name: c.name);
  }
  if (!spotById.containsKey(c.nodeId)) {
    final spot = NodeDto(
      nodeId: c.nodeId,
      building: c.building,
      floorLabel: c.floorLabel,
      title: c.name,
    ).toModel();
    if (spot != null) registerSpots([spot]);
  }
  return CampusPlace(id: c.nodeId, name: c.name);
}
