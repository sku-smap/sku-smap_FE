import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../campus/data/campus_directory.dart';
import '../../../campus/data/campus_models.dart';
import '../../../home/data/home_assets.dart';
import '../../../home/presentation/widgets/pressable.dart';
import '../../data/navigation_assets.dart';
import '../../data/navigation_models.dart';
import '../../data/route_graph.dart';
import '../../state/navigation_controller.dart';
import '../navigation_tokens.dart';

class RouteOverview extends StatelessWidget {
  const RouteOverview({
    super.key,
    required this.route,
    required this.stepIdx,
    required this.onStep,
    required this.onClose,
  });

  static const mapShare = 0.58;

  final ActiveRoute route;
  final int stepIdx;
  final ValueChanged<String> onStep;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: '전체 경로',
      child: ColoredBox(
        color: NavColors.field,
        child: LayoutBuilder(
          builder: (context, size) {
            final mapHeight = size.maxHeight * mapShare;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: mapHeight,
                  child: _RouteMap(path: route.path),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: mapHeight - NavLayout.sheetOverlap,
                  child: _Sheet(
                    route: route,
                    stepIdx: stepIdx,
                    onStep: onStep,
                    onClose: onClose,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.path});

  static const _mapW = 1024.0;
  static const _mapH = 684.0;

  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final nodes = [
      for (final id in path)
        if (spotById[id] case final n? when n.onMap) n,
    ];
    final under = nodes.where((n) => n.level == MapLevel.underground).length;
    final ground = under <= nodes.length / 2;
    final pts = [
      for (final n in nodes) Offset(n.x! / 100 * _mapW, n.y! / 100 * _mapH),
    ];

    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF2F6),
              Color(0xFFEEF2F6),
              Color(0xFFF5F7FA),
              Color(0xFFF5F7FA),
            ],
            stops: [0, 0.5, 0.5, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, size) {
            // Fit the whole route on screen, leaving room for pins and the sheet
            final xs = pts.map((p) => p.dx);
            final ys = pts.map((p) => p.dy);
            final x0 = xs.reduce(math.min), x1 = xs.reduce(math.max);
            final y0 = ys.reduce(math.min), y1 = ys.reduce(math.max);
            const padX = 36.0, padTop = 56.0, padBottom = 44.0;
            final viewH = size.maxHeight - NavLayout.sheetOverlap;
            final fitW = (size.maxWidth - padX * 2) / math.max(x1 - x0, 1);
            final fitH = (viewH - padTop - padBottom) / math.max(y1 - y0, 1);
            final k = math.max(
              math.min(math.min(fitW, fitH), NavLayout.overviewMaxZoom),
              0.1,
            );
            final tx = size.maxWidth / 2 - (x0 + x1) / 2 * k;
            final ty =
                padTop + (viewH - padTop - padBottom) / 2 - (y0 + y1) / 2 * k;
            final screen = [
              for (final p in pts) Offset(tx + p.dx * k, ty + p.dy * k),
            ];

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: tx,
                  top: ty,
                  width: _mapW * k,
                  height: _mapH * k,
                  child: SvgPicture.asset(
                    ground ? HomeAssets.mapGround : HomeAssets.mapUnderground,
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _OverviewPainter(screen, k)),
                ),
                _Pin(at: screen.first, label: '출발', color: NavColors.hero),
                _Pin(at: screen.last, label: '도착', color: NavColors.end),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OverviewPainter extends CustomPainter {
  const _OverviewPainter(this.pts, this.k);

  final List<Offset> pts;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Path()..addPolygon(pts, false);
    canvas
      ..drawPath(line, stroke(NavColors.surface, NavLayout.overviewCasing))
      ..drawPath(line, stroke(NavColors.hero, NavLayout.overviewLine));

    // Direction chevrons at an even on-screen spacing
    final arrow = stroke(NavColors.surface, 1.6);
    const gap = NavLayout.overviewArrowGap;
    var next = gap / 2;
    var walked = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final len = (b - a).distance;
      final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
      while (len > 0 && next <= walked + len) {
        final p = Offset.lerp(a, b, (next - walked) / len)!;
        canvas
          ..save()
          ..translate(p.dx, p.dy)
          ..rotate(angle)
          ..drawPath(
            Path()
              ..moveTo(-2.5, -3)
              ..lineTo(1.5, 0)
              ..lineTo(-2.5, 3),
            arrow,
          )
          ..restore();
        next += gap;
      }
      walked += len;
    }

    final dotStroke = stroke(NavColors.surface, 0.6 * k);
    for (final (p, color) in [
      (pts.first, NavColors.hero),
      (pts.last, NavColors.end),
    ]) {
      canvas
        ..drawCircle(p, 6, Paint()..color = color)
        ..drawCircle(p, 6, dotStroke);
    }
  }

  @override
  bool shouldRepaint(_OverviewPainter old) => old.pts != pts || old.k != k;
}

class _Pin extends StatelessWidget {
  const _Pin({required this.at, required this.label, required this.color});

  final Offset at;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: NavShadows.pin,
                ),
                child: Text(label, style: NavText.pin),
              ),
              CustomPaint(
                size: const Size(14, 7),
                painter: _TailPainter(color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

// Server thumbnail, else the full photo decoded at list size, else the
// bundled thumbnail
ImageProvider _thumbOf(ImageProvider Function(String url) photo, String id) {
  final spot = spotById[id];
  final url = spot?.thumbUrl ?? spot?.imageUrl;
  return url == null
      ? photo(NavigationAssets.thumb(id))
      : ResizeImage(photo(url), width: _thumbWidth);
}

const _thumbWidth = 320;

class _Sheet extends ConsumerWidget {
  const _Sheet({
    required this.route,
    required this.stepIdx,
    required this.onStep,
    required this.onClose,
  });

  final ActiveRoute route;
  final int stepIdx;
  final ValueChanged<String> onStep;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = routeStats(route.path, route.legs);
    final extras = [
      '도보',
      if (stats.stairs > 0) '계단 ${stats.stairs}번',
      if (stats.elevators > 0) '엘리베이터 ${stats.elevators}번',
    ];
    final photo = ref.read(photoImageProvider);
    final bottom = math.max(20.0, MediaQuery.paddingOf(context).bottom);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: NavColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: NavShadows.sheet,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.fromLTRB(0, 4, 0, 14),
              decoration: BoxDecoration(
                color: NavColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: '${route.last}',
                        children: [
                          const WidgetSpan(child: SizedBox(width: 2)),
                          TextSpan(text: '단계', style: NavText.routeUnit),
                        ],
                      ),
                      style: NavText.routeTotal,
                    ),
                    const SizedBox(height: 4),
                    Text(extras.join(' · '), style: NavText.routeExtra),
                  ],
                ),
              ),
              Semantics(
                container: true,
                child: Pressable(
                  onTap: onClose,
                  label: '닫기',
                  builder: (context, pressed) => Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pressed ? NavColors.line : NavColors.field,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      NavigationAssets.close,
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 0, 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: NavColors.field,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const _EndDot(color: NavColors.hero),
                const SizedBox(width: 6),
                Flexible(child: _EndName(route.from.label)),
                const SizedBox(width: 6),
                Text('→', style: NavText.routeArrow),
                const SizedBox(width: 6),
                const _EndDot(color: NavColors.end),
                const SizedBox(width: 6),
                Flexible(child: _EndName(route.to.label)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
            child: Text('단계별 안내 · ${route.last}단계', style: NavText.stepsTitle),
          ),
          for (final (i, id) in route.path.indexed)
            _StepRow(
              image: _thumbOf(photo, id),
              title: i == route.last
                  ? '도착 · ${route.to.label}'
                  : instruction(id, route.path[i + 1], route.legAt(i)),
              sub: spotById[id]?.title ?? '',
              done: i < stepIdx,
              current: i == stepIdx,
              onTap: () => onStep(id),
            ),
        ],
      ),
    );
  }
}

class _EndDot extends StatelessWidget {
  const _EndDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _EndName extends StatelessWidget {
  const _EndName(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: NavText.routeEnd,
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.image,
    required this.title,
    required this.sub,
    required this.done,
    required this.current,
    required this.onTap,
  });

  final ImageProvider image;
  final String title;
  final String sub;
  final bool done;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: done ? 0.5 : 1,
      child: Pressable(
        onTap: onTap,
        builder: (context, pressed) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: current
                  ? NavColors.blueSoft
                  : pressed
                  ? NavColors.field
                  : null,
              border: current
                  ? const Border(
                      left: BorderSide(color: NavColors.blue, width: 3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: image,
                    width: 72,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 72,
                      height: 44,
                      child: ColoredBox(color: NavColors.line),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: NavText.stepTitle),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: NavText.stepSub,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
