import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation_tokens.dart';

class ViewLink {
  const ViewLink({
    required this.to,
    required this.yaw,
    required this.label,
    this.sub,
    this.primary = false,
  });

  final String to;
  final double yaw;
  final String label;
  final String? sub;
  final bool primary;
}

// Arrow lying on the ground with chevrons flowing forward
class LinkArrow extends StatefulWidget {
  const LinkArrow({super.key, required this.link, required this.onTap});

  static const width = 160.0;
  static const height = 150.0;

  final ViewLink link;
  final VoidCallback onTap;

  @override
  State<LinkArrow> createState() => _LinkArrowState();
}

class _LinkArrowState extends State<LinkArrow>
    with SingleTickerProviderStateMixin {
  late final _flow = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.link.primary ? 1200 : 1800),
  )..repeat();

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    final size = link.primary ? 96.0 : 76.0;
    final sub = link.sub;
    return Semantics(
      button: true,
      label: link.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform(
              alignment: const Alignment(0, 0.3),
              transform: Matrix4.identity()
                ..setEntry(3, 2, 1 / 260)
                ..rotateX(58 * math.pi / 180),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      link.primary ? NavColors.linkGlow : NavColors.linkShade,
                      (link.primary ? NavColors.linkGlow : NavColors.linkShade)
                          .withValues(alpha: 0),
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _flow,
                  builder: (context, _) => CustomPaint(
                    painter: _ChevronPainter(
                      progress: _flow.value,
                      primary: link.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              constraints: const BoxConstraints(maxWidth: 150),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: link.primary ? NavColors.blue : NavColors.linkLabel,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    link.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: link.primary
                        ? NavText.linkLabel.copyWith(fontSize: 13)
                        : NavText.linkLabel,
                  ),
                  if (sub != null)
                    Text(
                      sub,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NavText.linkSub,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.progress, required this.primary});

  final double progress;
  final bool primary;

  @override
  void paint(Canvas canvas, Size size) {
    final arm = primary ? 30.0 : 24.0;
    final half = arm * math.sqrt1_2;
    final stroke = primary ? 7.0 : 6.0;
    final delay = primary ? 0.2 / 1.2 : 0.3 / 1.8;
    final center = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final t = (progress - delay * i) % 1;
      final eased = Curves.easeOut.transform(t);
      final opacity = t < 0.3 ? t / 0.3 : 1 - (t - 0.3) / 0.7;
      final y = center.dy + 18 - 38 * eased;
      final path = Path()
        ..moveTo(center.dx - half, y + half / 2)
        ..lineTo(center.dx, y - half / 2)
        ..lineTo(center.dx + half, y + half / 2);
      final glow = Paint()
        ..color = (primary ? NavColors.blue : Colors.black).withValues(
          alpha: (primary ? 0.95 : 0.5) * opacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, primary ? 6 : 3);
      final line = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round;
      canvas
        ..drawPath(path, glow)
        ..drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.progress != progress;
}
