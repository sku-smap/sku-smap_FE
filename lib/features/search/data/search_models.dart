import '../../home/data/campus_models.dart';

enum PickTarget { to, from }

enum PlaceKind {
  building('건물'),
  facility('시설'),
  office('부서'),
  professor('교수 연구실'),
  room('호실');

  const PlaceKind(this.label);

  final String label;
}

class SearchPlace {
  const SearchPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.node,
    this.sub,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final PlaceKind kind;
  final String node;
  final String? sub;
  final List<String> aliases;

  String get detail => sub == null ? kind.label : '${kind.label} · $sub';

  CampusPlace get spot => CampusPlace(id: id, name: name);

  SearchPlace copyWith({String? name, String? sub}) => SearchPlace(
    id: id,
    name: name ?? this.name,
    kind: kind,
    node: node,
    sub: sub ?? this.sub,
    aliases: aliases,
  );
}

class PanoSpot {
  const PanoSpot({
    required this.id,
    required this.title,
    required this.building,
    this.floor,
    required this.x,
    required this.y,
    this.level = MapLevel.ground,
    this.flat = false,
    this.hidden = false,
    this.center = false,
    this.estimated = false,
    this.roomList,
  });

  final String id;
  final String title;
  final String building;
  final String? floor;
  final double x;
  final double y;
  final MapLevel level;
  final bool flat;
  final bool hidden;
  final bool center;
  final bool estimated;
  final bool? roomList;

  bool get outdoor => building == 'outdoor';

  CampusPlace get spot => CampusPlace(id: id, name: title);
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
