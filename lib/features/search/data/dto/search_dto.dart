import '../../../campus/data/campus_models.dart';
import '../search_models.dart';

// POST /api/v1/searches response (SearchResponseDTO)
abstract final class SearchDto {
  static const _target = {
    'ORIGIN': SearchTarget.origin,
    'DESTINATION': SearchTarget.destination,
  };
  static const _option = {
    'OUTDOOR_FIRST': RouteOption.outdoorFirst,
    'COMFORTABLE': RouteOption.comfortable,
    'SHORTEST': RouteOption.shortest,
    'INDOOR_UNDERGROUND_FIRST': RouteOption.indoorUndergroundFirst,
  };

  static String targetName(SearchTarget t) =>
      _target.entries.firstWhere((e) => e.value == t).key;

  static String? _text(Object? s) {
    final t = (s as String?)?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  static SearchResult resultFrom(Object? data, SearchTarget asked) {
    final json = data! as Map<String, dynamic>;
    return SearchResult(
      target: _target[json['target']] ?? asked,
      searchId: (json['searchId'] as num?)?.toInt(),
      transcript: _text(json['transcript']),
      message: _text(json['message']),
      routeOption: _option[json['routeOption']],
      candidates: [
        for (final c in json['candidates'] as List? ?? const [])
          ?candidateFrom(c as Map<String, dynamic>),
      ],
    );
  }

  // RouteSearchResponseDTO: destination candidates plus the top start; a
  // sentence naming only the start has no destination candidates
  static SearchResult routeResultFrom(Object? data) {
    final json = data! as Map<String, dynamic>;
    SearchResult? part(Object? raw, SearchTarget target) =>
        raw == null ? null : resultFrom(raw, target);
    final to = part(json['destination'], SearchTarget.destination);
    final from = part(json['origin'], SearchTarget.origin);
    return SearchResult(
      target: SearchTarget.destination,
      searchId: to?.searchId,
      transcript: _text(json['transcript']) ?? to?.transcript,
      message: _text(json['message']) ?? to?.message,
      routeOption: to?.routeOption,
      candidates: to?.candidates ?? const [],
      origin: from?.candidates.firstOrNull,
    );
  }

  // Candidate, or null without an id, a node or a name
  static SearchCandidate? candidateFrom(Map<String, dynamic> json) {
    final id = _text(json['candidateId']);
    final node = _text(json['nodeId']);
    final name = _text(json['name']);
    if (id == null || node == null || name == null) return null;
    final placeId = _text(json['placeId']);
    return SearchCandidate(
      id: id,
      type: json['type'] == 'NODE' || placeId == null
          ? CandidateType.node
          : CandidateType.place,
      nodeId: node,
      name: name,
      placeId: placeId,
      sub: _text(json['displaySub']),
      building: _text(json['building']),
      floorLabel: _text(json['floorLabel']),
      kind:
          PlaceKind.values.where((k) => k.name == json['kind']).firstOrNull ??
          PlaceKind.facility,
      reason: _text(json['reason']),
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}
