import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../core/theme.dart';

abstract final class SearchColors {
  static const surface = AppColors.surface;
  static const field = AppColors.grey100;
  static const pressed = AppColors.grey100;
  static const headerLine = AppColors.grey900;
  static const text = AppColors.grey900;
  static const muted = AppColors.grey700;
  static const border = AppColors.grey200;
  static const blue = AppColors.blue;
  static const navy = AppColors.navy;
  static const blueSoft = AppColors.blueSoft;
  static const error = AppColors.error;

  static const placeholder = Color(0xFF757575);
  static const errorBg = Color(0xFFFFEEEE);

  static const voiceStops = [
    Color(0xFF3D8BFF),
    Color(0xFF1F79FF),
    Color(0xFF0F6FFF),
    AppColors.hero,
    Color(0xFF0052D6),
  ];
  static const voiceHint = AppColors.blueSoft;
  static const voiceText = Colors.white;
  static const voiceSub = Color(0xCCFFFFFF);
  static const voiceCaption = Color(0xA6FFFFFF);
  static const ghostChip = Color(0x1FFFFFFF);
}

abstract final class SearchShadows {
  static const mic = [
    BoxShadow(color: Color(0x59001E5A), offset: Offset(0, 10), blurRadius: 30),
  ];
}

abstract final class SearchLayout {
  static const headerHeight = 68.0;
  static const iconButton = 44.0;
  static const fieldHeight = 48.0;
  static const fieldRadius = 14.0;

  static const listInset = 8.0;
  static const rowRadius = 12.0;
  static const resultIcon = 40.0;
  static const resultIconRadius = 12.0;

  static const voiceTop = 60.0;
  static const voiceSide = 20.0;
  static const voiceBottom = 28.0;
  static const micSize = 96.0;
  static const micRing = 112.0;
  static const chipHeight = 38.0;
  static const chipGap = 8.0;
}

abstract final class SearchText {
  static const _base = TextStyle(
    fontFamily: appFontFamily,
    fontVariations: [FontVariation.weight(400)],
    color: SearchColors.text,
  );

  static final input = _base.copyWith(fontSize: 17, height: 22.1 / 17);
  static final inputHint = input.copyWith(color: SearchColors.placeholder);
  static final title = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    fontVariations: const [FontVariation.weight(800)],
    height: 24 / 20,
    color: SearchColors.navy,
  );
  static final caption = _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation.weight(600)],
    height: 15.6 / 13,
    color: SearchColors.muted,
  );
  static final rowTitle = _base.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
    height: 19.2 / 16,
  );
  static final rowSub = _base.copyWith(
    fontSize: 13,
    height: 15.6 / 13,
    color: SearchColors.muted,
  );
  static final empty = _base.copyWith(
    fontSize: 16,
    height: 25.6 / 16,
    color: SearchColors.muted,
  );
  static final error = _base.copyWith(
    fontSize: 13,
    height: 19.5 / 13,
    color: SearchColors.error,
  );

  static final voiceHint = _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
    height: 18 / 15,
    color: SearchColors.voiceHint,
  );
  static final voiceText = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    fontVariations: const [FontVariation.weight(800)],
    height: 37.8 / 28,
    color: SearchColors.voiceText,
  );
  static final voiceSub = _base.copyWith(
    fontSize: 14,
    height: 16.8 / 14,
    color: SearchColors.voiceSub,
  );
  static final voiceCaption = _base.copyWith(
    fontSize: 13,
    height: 15.6 / 13,
    color: SearchColors.voiceCaption,
  );
  static final chip = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontVariations: const [FontVariation.weight(600)],
    height: 16.8 / 14,
    color: SearchColors.navy,
  );
  static final ghostChip = chip.copyWith(color: Colors.white);
}
