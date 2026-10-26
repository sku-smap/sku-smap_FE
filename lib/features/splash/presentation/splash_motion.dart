import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';

import 'splash_tokens.dart';

// Eased progress of one keyframe segment, like a CSS animation with fill-mode both
double splashSegment(
  double elapsedMs,
  int startMs,
  int durationMs,
  Curve curve,
) {
  final t = ((elapsedMs - startMs) / durationMs).clamp(0.0, 1.0);
  return curve.transform(t);
}

// Lane light that dims and brightens on a loop after the pop-in
double laneFlowOpacity(double elapsedMs, int startMs) {
  final period = SplashTiming.laneFlowPeriod;
  final phase = ((elapsedMs - startMs) % period) / period;
  final dimming = phase < 0.5;
  final t = Curves.easeInOut.transform(dimming ? phase * 2 : phase * 2 - 1);
  return dimming
      ? lerpDouble(1, SplashMotion.laneDim, t)!
      : lerpDouble(SplashMotion.laneDim, 1, t)!;
}
