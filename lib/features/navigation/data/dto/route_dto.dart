import '../../../../core/network/app_exception.dart';
import '../../../campus/data/campus_models.dart';
import '../../../campus/data/dto/campus_map_dto.dart';
import '../navigation_models.dart';
import '../route_plan.dart';

// POST /api/v1/routes request option and response (RouteResponseDTO)
abstract final class RouteDto {
  static const _option = {
    RouteOption.outdoorFirst: 'OUTDOOR_FIRST',
    RouteOption.comfortable: 'COMFORTABLE',
    RouteOption.shortest: 'SHORTEST',
    RouteOption.indoorUndergroundFirst: 'INDOOR_UNDERGROUND_FIRST',
  };

  static String optionName(RouteOption o) => _option[o]!;

  // Segments must chain from start to goal; no segments means no route
  static RoutePlan? planFrom(
    Object? data, {
    required String from,
    required String to,
  }) {
    final json = data! as Map<String, dynamic>;
    final links = [
      for (final s in json['segments'] as List? ?? const [])
        ?CampusMapDto.edgeFrom(s as Map<String, dynamic>),
    ];
    if (links.isEmpty) {
      return from == to ? RoutePlan(path: [from], legs: const []) : null;
    }
    final path = [links.first.$1];
    final legs = <RouteLink>[];
    for (final (a, l) in links) {
      if (a != path.last) throw const ParseException('경로 데이터가 이어지지 않아요.');
      // A multi-floor elevator ride is one step
      if (l.via == Via.elevator && legs.lastOrNull?.via == Via.elevator) {
        path.last = l.to;
        legs.last = RouteLink(
          to: l.to,
          via: Via.elevator,
          note: legs.last.note,
        );
      } else {
        path.add(l.to);
        legs.add(l);
      }
    }
    if (path.first != from || path.last != to) {
      throw const ParseException('경로 데이터가 이어지지 않아요.');
    }
    return RoutePlan(
      path: path,
      legs: legs,
      links: links,
      spots: [
        for (final n in json['nodes'] as List? ?? const [])
          ?CampusMapDto.spotFrom(n as Map<String, dynamic>),
      ],
    );
  }
}
