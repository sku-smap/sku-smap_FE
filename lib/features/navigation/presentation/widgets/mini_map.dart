import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../home/data/campus_models.dart';
import '../../../home/data/home_assets.dart';
import '../../../search/data/search_models.dart';
import '../../data/navigation_models.dart';
import '../../data/campus_floors_mock.dart';
import '../../data/route_graph.dart';
import '../navigation_tokens.dart';
import 'glass_box.dart';

class MiniMap extends StatelessWidget {
  const MiniMap({
    super.key,
    required this.here,
    required this.route,
    required this.showMap,
    required this.onFloorSheet,
  });

  final PanoSpot here;
  final ActiveRoute? route;
  final bool showMap;
  final VoidCallback onFloorSheet;

  @override
  Widget build(BuildContext context) {
    final floor = here.outdoor ? null : here.floor;
    return GlassBox(
      radius: 14,
      shadow: NavShadows.map,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMap) _Stage(here: here, route: route),
          if (floor != null)
            _FloorLink(
              building: buildingNames[here.building] ?? '',
              floor: floor,
              rooms: roomsOn(here.building, floor).length,
              divided: showMap,
              onTap: onFloorSheet,
            ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.here, required this.route});

  final PanoSpot here;
  final ActiveRoute? route;

  @override
  Widget build(BuildContext context) {
    final r = route;
    final pts = [for (final id in r?.path ?? const <String>[]) ?spotById[id]];
    final target = r == null ? null : spotById[r.to.node];
    final ground = here.level == MapLevel.ground;
    return AspectRatio(
      aspectRatio: NavLayout.mapAspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: NavColors.mapStage,
          child: LayoutBuilder(
            builder: (context, size) {
              Offset at(PanoSpot n) =>
                  Offset(n.x / 100 * size.maxWidth, n.y / 100 * size.maxHeight);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      ground ? HomeAssets.mapGround : HomeAssets.mapUnderground,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (pts.length > 1)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RoutePainter([for (final p in pts) at(p)]),
                      ),
                    ),
                  if (pts.isNotEmpty) _Dot(at: at(pts.first), radius: 6),
                  if (target != null) _Dot(at: at(target), radius: 3, size: 12),
                  _Dot(at: at(here), radius: 8, size: 16),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: NavColors.navy,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        ground ? '지상' : '지하',
                        style: NavText.mapLevel,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.at, required this.radius, this.size = 12});

  final Offset at;
  final double radius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NavColors.blue,
          border: Border.all(color: NavColors.surface, width: 3),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addPolygon(points, false);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, stroke(NavColors.surface, NavLayout.miniCasing))
      ..drawPath(path, stroke(NavColors.hero, NavLayout.miniLine));
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.points != points;
}

class _FloorLink extends StatelessWidget {
  const _FloorLink({
    required this.building,
    required this.floor,
    required this.rooms,
    required this.divided,
    required this.onTap,
  });

  final String building;
  final String floor;
  final int rooms;
  final bool divided;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final short = floor == 'L층' ? 'L' : floor.replaceFirst('층', 'F');
    return Semantics(
      button: true,
      label: '$floor 층 안내도 열기',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: divided
                ? const Border(top: BorderSide(color: NavColors.line))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$building $short',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NavText.floorName,
                ),
              ),
              Text('층 안내도', style: NavText.floorLink),
              if (rooms > 0) ...[
                const SizedBox(width: 4),
                Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NavColors.blueSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text('$rooms', style: NavText.floorCount),
                ),
              ],
              const SizedBox(width: 4),
              Text('›', style: NavText.floorChevron),
            ],
          ),
        ),
      ),
    );
  }
}
