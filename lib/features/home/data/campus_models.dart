enum MapLevel { ground, underground }

enum RouteMode { outdoor, elevator }

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
  const Closure({required this.place, this.type, this.until});

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
