import 'package:flutter/material.dart';

import 'app_colors.dart';

const appFontFamily = 'Pretendard Variable';

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    scaffoldBackgroundColor: AppColors.grey100,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      surface: AppColors.surface,
    ),
  );
}
