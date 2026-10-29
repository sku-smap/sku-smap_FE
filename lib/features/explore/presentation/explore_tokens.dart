import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../navigation/presentation/navigation_tokens.dart';

abstract final class ExploreColors {
  static const editBg = Color(0xFFFFF9E7);
}

abstract final class ExploreLayout {
  static const cardPadding = EdgeInsets.fromLTRB(16, 15, 16, 15);
  static const textGap = 16.0;
  static const buttonGap = 8.0;
  static const buttonPadding = 20.0;
  static const flagIcon = 22.0;

  static const editWidth = 234.0;
  static const editPadding = 10.0;
  static const editGap = 8.0;
  static const editRadius = 14.0;
  static const editChipHeight = 32.0;
  static const editChipGap = 6.0;
  static const editButtonHeight = 36.0;
  static const editButtonRadius = 12.0;
  static const editSide = 16.0;
}

abstract final class ExploreText {
  static final sub = NavText.stepHint.copyWith(fontSize: 12, height: 14.4 / 12);
  static final title = NavText.whereTitle.copyWith(
    fontSize: 17,
    height: 20.4 / 17,
  );
  static final button = NavText.button.copyWith(color: NavColors.surface);

  static const _edit = TextStyle(
    fontFamily: appFontFamily,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
    color: NavColors.text,
  );
  static final editHint = _edit.copyWith(fontSize: 13, height: 19.5 / 13);
  static final editChip = _edit.copyWith(fontSize: 14, height: 21 / 14);
  static final editButton = _edit.copyWith(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation.weight(700)],
    color: NavColors.surface,
  );
}
