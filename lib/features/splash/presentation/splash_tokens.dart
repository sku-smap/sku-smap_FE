import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme.dart';

abstract final class SplashColors {
  static const background = Color(0xFF0066FF);
  static const content = Colors.white;
  static const chip = Color(0x33FFFFFF);
}

abstract final class SplashLayout {
  static const frameWidth = 390.0;
  static const roadHeight = 497.0;
  static const textReserve = 250.0;
  static const textInset = 24.0;
  static const textBottom = 96.0;

  static const roadUpper = Rect.fromLTWH(-86, -110, 492, 584);
  static const roadLower = Rect.fromLTWH(114.18, 85.29, 364.51, 410.74);
  static const lanes = [
    Rect.fromLTWH(155.52, 349.8, 92.46, 101.15),
    Rect.fromLTWH(201.92, 218.3, 51.63, 87.52),
    Rect.fromLTWH(131, 150, 49.6, 38.66),
    Rect.fromLTWH(76.44, 110.75, 37.89, 25.46),
    Rect.fromLTWH(59.66, 103.27, 12.23, 6.69),
  ];

  static const titleSize = Size(200, 70);
  static const letterOffsets = [0.0, 26.5, 72.0, 101.5];
  static const titleGap = 9.0;
  static const chipGap = 6.0;
  static const chipRadius = 6.0;
  static const chipPadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
}

abstract final class SplashTextStyles {
  static const title = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(800)],
    letterSpacing: -1.56,
    color: SplashColors.content,
  );
  static const tagline = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
    color: SplashColors.content,
  );
  static const chip = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
    color: SplashColors.content,
  );
  static const nfcMessage = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
    height: 1.4,
    color: SplashColors.content,
  );
}

abstract final class SplashTiming {
  static const defaultTotal = 2200;
  static const nfcTotal = 2800;
  static const reducedTotal = 1000;
  static const exit = 350;

  static const zoom = 1500;
  static const unroll = 700;
  static const lowerRoadDelay = 100;

  static const lanePopStart = 550;
  static const lanePop = 400;
  static const laneStagger = 70;
  static const laneFlowStart = 1050;
  static const laneFlowPeriod = 700;

  static const letterStart = 800;
  static const letterPop = 500;
  static const letterStagger = 70;

  static const captionStart = 1200;
  static const captionRise = 450;
}

abstract final class SplashMotion {
  static const zoomCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const unrollCurve = Cubic(0.5, 0, 0.15, 1);
  static const lanePopCurve = Cubic(0.3, 1.8, 0.5, 1);
  static const letterCurve = Cubic(0.3, 1.6, 0.5, 1);

  static const zoomScale = 1.18;
  static const zoomAngle = -5 * math.pi / 180;
  static const unrollShift = 0.06;
  static const unrollOverscan = 0.02;
  static const laneDim = 0.35;
  static const letterRise = 60.0;
  static const letterTilt = 8 * math.pi / 180;
  static const captionRise = 40.0;
  static const taglineOpacity = 0.9;
  static const exitGrow = 0.06;
}
