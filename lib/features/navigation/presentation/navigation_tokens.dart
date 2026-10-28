import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../home/presentation/home_tokens.dart';

abstract final class NavColors {
  static const surface = AppColors.surface;
  static const text = AppColors.grey900;
  static const muted = AppColors.grey700;
  static const placeholder = AppColors.grey500;
  static const line = AppColors.grey200;
  static const field = AppColors.grey100;
  static const blue = AppColors.blue;
  static const navy = AppColors.navy;
  static const blueSoft = AppColors.blueSoft;
  static const hero = AppColors.hero;
  static const mapStage = HomeColors.mapStage;

  static const glass = Color(0xE6FFFFFF);
  static const glassOff = Color(0x0F00156A);
  static const floorButton = Color(0x0F194AA6);
  static const pressed = Color(0xFF1B64DA);
  static const end = Color(0xFFE5322D);
  static const estimatedText = Color(0xFFB26A00);
  static const estimatedBg = Color(0xFFFFF3DC);
  static const photoBg = Color(0xFF0B0F1E);
  static const loading = Color(0xCC00156A);
  static const linkLabel = Color(0x9E0F141E);
  static const linkSub = Color(0xFFC9E2FF);
  static const linkShade = Color(0x4D000000);
  static const linkGlow = Color(0x8C2272EB);
  static const markX = Color(0x2EEF4444);
  static const markLabel = Color(0xB3000000);
  static const overlay = Color(0xCC000000);
  static const overlayRow = Color(0x1FFFFFFF);
}

abstract final class NavShadows {
  static const glass = [
    BoxShadow(color: Color(0x2E000000), offset: Offset(0, 2), blurRadius: 12),
  ];
  static const map = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 12),
  ];
  static const card = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 8), blurRadius: 30),
  ];
  static const pin = [
    BoxShadow(color: Color(0x4D00146B), offset: Offset(0, 3), blurRadius: 8),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x1A00146B), offset: Offset(0, -4), blurRadius: 16),
  ];
}

abstract final class NavLayout {
  static const edge = 12.0;
  static const topButton = 44.0;
  static const topRadius = 12.0;
  static const whereRadius = 14.0;
  static const mapTop = 58.0;
  static const mapWidth = 0.46;
  static const mapMaxWidth = 200.0;
  static const mapAspect = 171.4 / 114.5;
  static const floorBarTop = 250.0;

  static const cardInset = 10.0;
  static const cardRadius = 22.0;
  static const buttonHeight = 48.0;
  static const buttonRadius = 14.0;
  static const toolButton = 38.0;

  static const miniCasing = 9.8;
  static const miniLine = 5.6;
  static const overviewCasing = 12.0;
  static const overviewLine = 8.0;
  static const overviewArrowGap = 46.0;
  static const overviewMaxZoom = 2.5;
  static const sheetOverlap = 24.0;
}

abstract final class NavText {
  static const _base = TextStyle(
    fontFamily: appFontFamily,
    fontVariations: [FontVariation.weight(400)],
    color: NavColors.text,
  );

  static TextStyle _w(TextStyle s, int weight) => s.copyWith(
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation.weight(weight.toDouble())],
  );

  static final wherePlace = _w(
    _base.copyWith(fontSize: 12, height: 14.4 / 12, color: NavColors.blue),
    700,
  );
  static final whereTitle = _w(
    _base.copyWith(fontSize: 15, height: 18 / 15, color: NavColors.navy),
    700,
  );
  static final estimated = _w(
    _base.copyWith(fontSize: 10, color: NavColors.estimatedText),
    800,
  );
  static final mapLevel = _w(
    _base.copyWith(fontSize: 11, height: 13.2 / 11, color: Colors.white),
    800,
  );
  static final floorName = _w(
    _base.copyWith(fontSize: 12, height: 14.4 / 12, color: NavColors.navy),
    800,
  );
  static final floorLink = _w(
    _base.copyWith(fontSize: 12, height: 14.4 / 12, color: NavColors.blue),
    700,
  );
  static final floorCount = _w(
    _base.copyWith(fontSize: 11, height: 18 / 11, color: NavColors.blue),
    700,
  );
  static final floorChevron = _w(
    _base.copyWith(fontSize: 15, height: 18 / 15, color: NavColors.placeholder),
    700,
  );
  static final floorBarName = _w(
    _base.copyWith(fontSize: 10, height: 12 / 10, color: NavColors.muted),
    800,
  );
  static final floorButton = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: NavColors.navy),
    800,
  );

  static final stepCount = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: NavColors.blue),
    800,
  );
  static final stepDest = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: NavColors.muted),
    600,
  );
  static final stepText = _w(
    _base.copyWith(fontSize: 21, height: 28.4 / 21, letterSpacing: -0.42),
    800,
  );
  static final stepNote = _w(
    _base.copyWith(fontSize: 14, height: 1.45, color: NavColors.blue),
    600,
  );
  static final stepHint = _base.copyWith(
    fontSize: 13,
    height: 15.6 / 13,
    color: NavColors.muted,
  );
  static final rateDone = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: NavColors.blue),
    700,
  );
  static final rateChip = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: NavColors.navy),
    600,
  );
  static final button = _w(
    _base.copyWith(fontSize: 16, height: 19.2 / 16, color: NavColors.navy),
    700,
  );

  static final linkLabel = _w(
    _base.copyWith(fontSize: 12, height: 1.3, color: Colors.white),
    700,
  );
  static final linkSub = _w(
    _base.copyWith(fontSize: 11, height: 1.3, color: NavColors.linkSub),
    600,
  );
  static final tagName = _w(_base.copyWith(fontSize: 14), 700);
  static final markLabel = _w(
    _base.copyWith(fontSize: 13, color: Colors.white),
    700,
  );
  static final loading = _base.copyWith(fontSize: 14, color: Colors.white);

  static final routeTime = _w(
    _base.copyWith(fontSize: 34, height: 39.1 / 34, letterSpacing: -0.5),
    800,
  );
  static final routeUnit = _w(
    _base.copyWith(fontSize: 22, height: 25.3 / 22, letterSpacing: -0.5),
    800,
  );
  static final routeExtra = _w(
    _base.copyWith(fontSize: 14, height: 16.8 / 14, color: NavColors.muted),
    600,
  );
  static final routeGuess = _w(
    _base.copyWith(
      fontSize: 14,
      height: 16.8 / 14,
      color: NavColors.placeholder,
    ),
    500,
  );
  static final routeEnd = _w(
    _base.copyWith(fontSize: 14, height: 16.8 / 14),
    700,
  );
  static final routeArrow = _base.copyWith(
    fontSize: 14,
    height: 16.8 / 14,
    color: NavColors.placeholder,
  );
  static final stepsTitle = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: NavColors.muted),
    700,
  );
  static final stepTitle = _w(
    _base.copyWith(fontSize: 14, height: 18.9 / 14),
    700,
  );
  static final stepSub = _base.copyWith(
    fontSize: 12,
    height: 14.4 / 12,
    color: NavColors.muted,
  );
  static final pin = _w(
    _base.copyWith(fontSize: 14, height: 16.8 / 14, color: Colors.white),
    700,
  );

  static final sheetTitle = _w(
    _base.copyWith(fontSize: 21, letterSpacing: -0.42, color: NavColors.navy),
    800,
  );
  static final sheetSub = _base.copyWith(
    fontSize: 15,
    height: 1.5,
    color: NavColors.muted,
  );
  static final groupTitle = _w(
    _base.copyWith(fontSize: 14, color: NavColors.navy),
    800,
  );
  static final groupCount = _w(
    _base.copyWith(fontSize: 14, color: NavColors.placeholder),
    700,
  );
  static final roomNo = _w(
    _base.copyWith(
      fontSize: 15,
      color: NavColors.blue,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
    800,
  );
  static final roomName = _base.copyWith(fontSize: 15, height: 1.35);
  static final overlayHead = _w(
    _base.copyWith(fontSize: 13, color: Colors.white),
    700,
  );
  static final overlayToggle = _base.copyWith(
    fontSize: 12,
    color: Colors.white.withValues(alpha: 0.7),
  );
  static final overlayRow = _base.copyWith(
    fontSize: 13,
    height: 1.35,
    color: Colors.white,
  );
}
