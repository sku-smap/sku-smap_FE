import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';
import '../../home/presentation/home_tokens.dart';
import '../../search/presentation/search_tokens.dart';

abstract final class ReportColors {
  static const surface = AppColors.surface;
  static const background = AppColors.grey100;
  static const field = AppColors.grey100;
  static const line = AppColors.grey200;
  static const disabled = AppColors.grey300;
  static const text = AppColors.grey900;
  static const muted = AppColors.grey700;
  static const placeholder = AppColors.grey500;
  static const blue = AppColors.blue;
  static const navy = AppColors.navy;
  static const blueSoft = AppColors.blueSoft;
  static const pressed = Color(0xFF1B64DA);
  static const headerLine = SearchColors.headerLine;
  static const memoHint = SearchColors.placeholder;
  static const closure = HomeColors.closure;
  static const backdrop = HomeColors.backdrop;
  static const local = Color(0xFF8A6D00);
}

abstract final class ReportShadows {
  static const card = HomeShadows.card;
}

abstract final class ReportLayout {
  static const sheetRadius = 24.0;
  static const sheetMaxHeight = 0.86;
  static const sheetSide = 16.0;
  static const gripWidth = 40.0;
  static const gripHeight = 5.0;

  static const kindRadius = 16.0;
  static const kindPadding = 14.0;
  static const kindIcon = 44.0;
  static const kindIconRadius = 12.0;
  static const kindGap = 8.0;

  static const iconButton = 44.0;
  static const backIcon = 22.0;
  static const fieldGap = 16.0;
  static const labelGap = 8.0;
  static const chipHeight = 38.0;
  static const smallChipHeight = 34.0;
  static const chipGap = 6.0;
  static const locHeight = 48.0;
  static const fieldRadius = 12.0;
  static const photoAddHeight = 52.0;
  static const photoWidth = 120.0;
  static const photoHeight = 90.0;
  static const memoHeight = 80.0;
  static const buttonHeight = 48.0;
  static const buttonRadius = 14.0;
  static const meDot = 16.0;

  static const headerHeight = 64.0;
  static const cardRadius = 16.0;
  static const cardPadding = 14.0;
  static const cardGap = 10.0;
  static const stepDot = 10.0;
  static const stepLine = 2.0;
}

abstract final class ReportText {
  static const _base = TextStyle(
    fontFamily: appFontFamily,
    fontVariations: [FontVariation.weight(400)],
    color: ReportColors.text,
  );

  static TextStyle _w(TextStyle s, int weight) => s.copyWith(
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation.weight(weight.toDouble())],
  );

  static final sheetTitle = _w(
    _base.copyWith(fontSize: 21, height: 25.2 / 21, color: ReportColors.navy),
    800,
  );
  static final sheetSub = _base.copyWith(
    fontSize: 15,
    height: 22.5 / 15,
    color: ReportColors.muted,
  );
  static final kindIcon = _base.copyWith(fontSize: 22, height: 26.4 / 22);
  static final kindTitle = _w(
    _base.copyWith(fontSize: 16, height: 19.2 / 16),
    700,
  );
  static final kindSub = _base.copyWith(
    fontSize: 13,
    height: 15.6 / 13,
    color: ReportColors.muted,
  );
  static final mineLink = _w(
    _base.copyWith(fontSize: 14, height: 16.8 / 14, color: ReportColors.blue),
    700,
  );
  static final label = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: ReportColors.muted),
    700,
  );
  static final locValue = _w(
    _base.copyWith(fontSize: 15, height: 18 / 15),
    700,
  );
  static final locEmpty = _w(
    locValue.copyWith(color: ReportColors.placeholder),
    600,
  );
  static final locSmall = _w(
    _base.copyWith(fontSize: 12, height: 14.4 / 12, color: ReportColors.muted),
    600,
  );
  static final chip = _w(
    _base.copyWith(fontSize: 14, height: 16.8 / 14, color: ReportColors.navy),
    600,
  );
  static final smallChip = chip.copyWith(fontSize: 13, height: 15.6 / 13);
  static final hint = _base.copyWith(
    fontSize: 12,
    height: 14.4 / 12,
    color: ReportColors.muted,
  );
  static final memo = _base.copyWith(fontSize: 15, height: 19.5 / 15);
  static final memoHint = memo.copyWith(color: ReportColors.memoHint);
  static final button = _w(
    _base.copyWith(
      fontSize: 16,
      height: 19.2 / 16,
      color: ReportColors.surface,
    ),
    700,
  );

  static final headerTitle = _w(
    _base.copyWith(fontSize: 17, height: 20.4 / 17),
    700,
  );
  static final cardIcon = _base.copyWith(fontSize: 16, height: 19.2 / 16);
  static final cardTitle = _w(
    _base.copyWith(fontSize: 15, height: 18 / 15),
    700,
  );
  static final cardDate = _base.copyWith(
    fontSize: 12,
    height: 14.4 / 12,
    color: ReportColors.muted,
  );
  static final cardWhere = _w(
    _base.copyWith(fontSize: 14, height: 16.8 / 14, color: ReportColors.navy),
    600,
  );
  static final cardMemo = _base.copyWith(
    fontSize: 13,
    height: 19.5 / 13,
    color: ReportColors.muted,
  );
  static final step = _w(
    _base.copyWith(
      fontSize: 12,
      height: 14.4 / 12,
      color: ReportColors.placeholder,
    ),
    600,
  );
  static final thanks = _w(
    _base.copyWith(fontSize: 13, height: 15.6 / 13, color: ReportColors.blue),
    700,
  );
  static final local = _base.copyWith(
    fontSize: 12,
    height: 14.4 / 12,
    color: ReportColors.local,
  );
  static final rejected = _base.copyWith(
    fontSize: 13,
    height: 15.6 / 13,
    color: ReportColors.muted,
  );
  static final message = _base.copyWith(
    fontSize: 14,
    height: 16.8 / 14,
    color: ReportColors.muted,
  );
  static final empty = _base.copyWith(
    fontSize: 16,
    height: 25.6 / 16,
    color: ReportColors.muted,
  );
}
