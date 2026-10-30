enum MapLevel { ground, underground }

enum RouteMode { outdoor, comfortable, shortest }

// Route preference read from a search sentence; passed on to the route API
enum RouteOption { outdoorFirst, comfortable, shortest, indoorUndergroundFirst }

enum FacilityCategory {
  store('매점·편의점'),
  food('식당'),
  cafe('카페'),
  atm('ATM·은행'),
  post('우체국'),
  print('복사·서점');

  const FacilityCategory(this.label);

  final String label;
}

enum WetKind {
  rain('☔', '비가'),
  sleet('🌨️', '진눈깨비가'),
  snow('❄️', '눈이');

  const WetKind(this.icon, this.subject);

  final String icon;
  final String subject;
}

class CampusPlace {
  const CampusPlace({required this.id, required this.name});

  final String id;
  final String name;
}

class CampusBuilding {
  const CampusBuilding({
    required this.id,
    required this.name,
    required this.mapX,
    required this.mapY,
    required this.description,
    this.departments,
    this.photo,
    this.floors = const [],
    this.places = const [],
    this.roomCount = 0,
  });

  final String id;
  final String name;
  final double mapX;
  final double mapY;
  final String description;
  final String? departments;
  final String? photo;
  final List<String> floors;
  final List<CampusPlace> places;
  final int roomCount;

  CampusPlace get main => CampusPlace(id: 'b-$id', name: name);
}

class FacilitySpot {
  const FacilitySpot({
    required this.category,
    required this.building,
    required this.mapX,
    required this.mapY,
    required this.places,
    this.level = MapLevel.ground,
  });

  final FacilityCategory category;
  final String building;
  final double mapX;
  final double mapY;
  final List<CampusPlace> places;
  final MapLevel level;

  String get pinLabel {
    final more = places.length > 1 ? ' 외 ${places.length - 1}' : '';
    return '$building ${places.first.name}$more';
  }
}

class Closure {
  const Closure({
    required this.node,
    required this.place,
    this.type,
    this.until,
  });

  final String node;
  final String place;
  final String? type;
  final String? until;

  String get summary =>
      [place, ?type, if (until != null) '$until까지'].join(' · ');
}

class CampusWeather {
  const CampusWeather({this.wetKind, this.temperature});

  final WetKind? wetKind;
  final double? temperature;

  bool get isWet => wetKind != null;
}

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
    this.x,
    this.y,
    this.level = MapLevel.ground,
    this.flat = false,
    this.hidden = false,
    this.center = false,
    this.estimated = false,
    this.imageUrl,
    this.thumbUrl,
  });

  final String id;
  final String title;
  final String building;
  final String? floor;
  final double? x;
  final double? y;
  final MapLevel level;
  final bool flat;
  final bool hidden;
  final bool center;
  final bool estimated;
  final String? imageUrl;

  // Small list photo; may be missing even when the full photo exists
  final String? thumbUrl;

  bool get outdoor => building == 'outdoor';

  // Spots only the server knows have no map position yet
  bool get onMap => x != null && y != null;

  CampusPlace get spot => CampusPlace(id: id, name: title);

  PanoSpot withPhoto(String? url, {String? thumb}) => PanoSpot(
    id: id,
    title: title,
    building: building,
    floor: floor,
    x: x,
    y: y,
    level: level,
    flat: flat,
    hidden: hidden,
    center: center,
    estimated: estimated,
    imageUrl: url,
    thumbUrl: thumb,
  );

  // Server name, building, floor and photo over the bundled map data; a
  // server photo brings its own photo type
  PanoSpot withServer(PanoSpot server) => PanoSpot(
    id: id,
    title: server.title,
    building: server.building,
    floor: server.floor,
    x: x,
    y: y,
    level: level,
    flat: server.imageUrl != null ? server.flat : flat,
    hidden: hidden,
    center: center,
    estimated: estimated,
    imageUrl: server.imageUrl ?? imageUrl,
    thumbUrl: server.imageUrl != null ? server.thumbUrl : thumbUrl,
  );
}
