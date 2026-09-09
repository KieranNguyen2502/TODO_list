import 'package:flutter/material.dart';

class AppColors {
  static const purple = Color(0xFF6B4FA0);
  static const background = Color(0xFFF3EEF9);
  static const cardBackground = Colors.white;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
}
