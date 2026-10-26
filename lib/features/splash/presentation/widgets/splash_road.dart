import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/splash_assets.dart';
import '../splash_motion.dart';
import '../splash_tokens.dart';

class SplashRoad extends StatelessWidget {
  const SplashRoad({super.key, required this.elapsedMs, required this.still});

  final double elapsedMs;
  final bool still;

  double _segment(int startMs, int durationMs, Curve curve) =>
      still ? 1 : splashSegment(elapsedMs, startMs, durationMs, curve);

  @override
  Widget build(BuildContext context) {
    final zoom = _segment(0, SplashTiming.zoom, SplashMotion.zoomCurve);
    final scale = lerpDouble(SplashMotion.zoomScale, 1, zoom)!;
    final angle = lerpDouble(SplashMotion.zoomAngle, 0, zoom)!;

    // Camera settles from a tilted close-up back to the frame
    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.diagonal3Values(scale, scale, 1)..rotateZ(angle),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: SplashLayout.frameWidth,
          height: SplashLayout.roadHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _UnrollLayer(
                rect: SplashLayout.roadUpper,
                asset: SplashAssets.roadUpper,
                fromTop: true,
                progress: _segment(
                  0,
                  SplashTiming.unroll,
                  SplashMotion.unrollCurve,
                ),
              ),
              _UnrollLayer(
                rect: SplashLayout.roadLower,
                asset: SplashAssets.roadLower,
                fromTop: false,
                progress: _segment(
                  SplashTiming.lowerRoadDelay,
                  SplashTiming.unroll,
                  SplashMotion.unrollCurve,
                ),
              ),
              for (var i = 0; i < SplashAssets.lanes.length; i++)
                _LaneLayer(
                  rect: SplashLayout.lanes[i],
                  asset: SplashAssets.lanes[i],
                  elapsedMs: elapsedMs,
                  index: i,
                  still: still,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnrollLayer extends StatelessWidget {
  const _UnrollLayer({
    required this.rect,
    required this.asset,
    required this.fromTop,
    required this.progress,
  });

  final Rect rect;
  final String asset;
  final bool fromTop;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final shift = SplashMotion.unrollShift * rect.height * (1 - progress);

    return Positioned.fromRect(
      rect: rect,
      child: Transform.translate(
        offset: Offset(0, fromTop ? -shift : shift),
        child: ClipRect(
          clipper: _UnrollClipper(progress: progress, fromTop: fromTop),
          child: SvgPicture.asset(
            asset,
            width: rect.width,
            height: rect.height,
          ),
        ),
      ),
    );
  }
}

class _UnrollClipper extends CustomClipper<Rect> {
  const _UnrollClipper({required this.progress, required this.fromTop});

  final double progress;
  final bool fromTop;

  // Reveal the road from one edge, overscanning slightly at the end
  @override
  Rect getClip(Size size) {
    final reveal = size.height * (1 + SplashMotion.unrollOverscan) * progress;
    return fromTop
        ? Rect.fromLTRB(0, 0, size.width, reveal)
        : Rect.fromLTRB(0, size.height - reveal, size.width, size.height);
  }

  @override
  bool shouldReclip(_UnrollClipper oldClipper) =>
      oldClipper.progress != progress || oldClipper.fromTop != fromTop;
}

class _LaneLayer extends StatelessWidget {
  const _LaneLayer({
    required this.rect,
    required this.asset,
    required this.elapsedMs,
    required this.index,
    required this.still,
  });

  final Rect rect;
  final String asset;
  final double elapsedMs;
  final int index;
  final bool still;

  @override
  Widget build(BuildContext context) {
    final stagger = SplashTiming.laneStagger * index;
    final flowStart = SplashTiming.laneFlowStart + stagger;
    final pop = still
        ? 1.0
        : splashSegment(
            elapsedMs,
            SplashTiming.lanePopStart + stagger,
            SplashTiming.lanePop,
            SplashMotion.lanePopCurve,
          );
    final opacity = still
        ? 1.0
        : elapsedMs < flowStart
        ? pop.clamp(0.0, 1.0)
        : laneFlowOpacity(elapsedMs, flowStart);

    // Pop lanes in nearest-first, then pulse their light
    return Positioned.fromRect(
      rect: rect,
      child: Transform.scale(
        scale: pop,
        child: Opacity(
          opacity: opacity,
          child: SvgPicture.asset(
            asset,
            width: rect.width,
            height: rect.height,
          ),
        ),
      ),
    );
  }
}
