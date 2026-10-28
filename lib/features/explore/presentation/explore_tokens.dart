import 'package:flutter/material.dart';

import '../../navigation/presentation/navigation_tokens.dart';

abstract final class ExploreLayout {
  static const cardPadding = EdgeInsets.fromLTRB(16, 15, 16, 15);
  static const textGap = 16.0;
  static const buttonGap = 8.0;
  static const buttonPadding = 20.0;
  static const flagIcon = 22.0;
}

abstract final class ExploreText {
  static final sub = NavText.stepHint.copyWith(fontSize: 12, height: 14.4 / 12);
  static final title = NavText.whereTitle.copyWith(
    fontSize: 17,
    height: 20.4 / 17,
  );
  static final button = NavText.button.copyWith(color: NavColors.surface);
}
