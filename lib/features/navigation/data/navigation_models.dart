enum Via {
  walk('도보', 1),
  door('출입구', 1),
  passage('연결통로', 2),
  stairs('계단', 2.5),
  elevator('엘리베이터', 3);

  const Via(this.label, this.cost);

  final String label;
  final double cost;
}

class RouteLink {
  const RouteLink({
    required this.to,
    required this.via,
    this.note,
    this.through,
    this.fromServer = false,
    this.yaw,
  });

  final String to;
  final Via via;
  final String? note;
  final String? through;

  // Added from the campus map or a route
  final bool fromServer;

  // Arrow direction in the start photo (0–360°); null when unknown, unlike 0
  final double? yaw;

  RouteLink copyWith({required Via via, required String through}) => RouteLink(
    to: to,
    via: via,
    note: note,
    through: through,
    fromServer: fromServer,
    yaw: yaw,
  );

  RouteLink withYaw(double yaw) => RouteLink(
    to: to,
    via: via,
    note: note,
    through: through,
    fromServer: fromServer,
    yaw: yaw,
  );
}

class FloorStop {
  const FloorStop({
    required this.floor,
    required this.label,
    required this.node,
  });

  final String floor;
  final String label;
  final String node;
}

class FloorRoom {
  const FloorRoom({
    required this.no,
    required this.name,
    required this.use,
    this.field = false,
  });

  final String no;
  final String name;
  final String use;
  final bool field;
}

class PanoMark {
  const PanoMark({
    required this.yaw,
    required this.pitch,
    required this.title,
    required this.desc,
    this.label = false,
  });

  final double yaw;
  final double pitch;
  final String title;
  final String desc;
  final bool label;
}

class RouteEnd {
  const RouteEnd({
    required this.id,
    required this.node,
    required this.label,
    this.sub,
  });

  final String id;
  final String node;
  final String label;
  final String? sub;
}

class ActiveRoute {
  const ActiveRoute({
    required this.from,
    required this.to,
    required this.path,
    this.legs = const [],
  });

  final RouteEnd from;
  final RouteEnd to;
  final List<String> path;

  // legs[i] goes from path[i] to path[i + 1]
  final List<RouteLink> legs;

  int get last => path.length - 1;

  RouteLink? legAt(int i) => i >= 0 && i < legs.length ? legs[i] : null;
}

class RouteStats {
  const RouteStats({required this.elevators, required this.stairs});

  final int elevators;
  final int stairs;
}
