import '../../campus/data/campus_models.dart';

enum PickTarget { to, from }

enum SearchTarget { origin, destination }

enum CandidateType { place, node }

// One server search candidate (CandidateDTO)
class SearchCandidate {
  const SearchCandidate({
    required this.id,
    required this.type,
    required this.nodeId,
    required this.name,
    this.placeId,
    this.sub,
    this.building,
    this.floorLabel,
    this.kind = PlaceKind.facility,
    this.reason,
    this.score,
  });

  // candidateId, sent back as is when a candidate is confirmed
  final String id;
  final CandidateType type;
  final String nodeId;
  final String name;
  final String? placeId;
  final String? sub;
  final String? building;
  final String? floorLabel;
  final PlaceKind kind;
  final String? reason;
  final double? score;
}

class SearchResult {
  const SearchResult({
    required this.target,
    this.searchId,
    this.transcript,
    this.message,
    this.routeOption,
    this.candidates = const [],
    this.origin,
  });

  final SearchTarget target;
  final int? searchId;
  final String? transcript;
  final String? message;
  final RouteOption? routeOption;
  final List<SearchCandidate> candidates;

  // Start named in the same sentence; only the bundled rules find it
  final SearchCandidate? origin;
}

class SearchTask {
  const SearchTask({
    required this.label,
    required this.keywords,
    required this.place,
    this.dest,
    required this.reply,
    required this.checked,
  });

  final String label;
  final List<String> keywords;
  final String place;
  final String? dest;
  final String reply;
  final bool checked;
}

class VoiceIntent {
  const VoiceIntent({
    this.from,
    this.to,
    this.candidates = const [],
    this.avoidStairs = false,
    this.reply,
  });

  final SearchPlace? from;
  final SearchPlace? to;
  final List<SearchPlace> candidates;
  final bool avoidStairs;
  final String? reply;
}
