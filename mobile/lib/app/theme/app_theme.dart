import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.dark(
      surface: AppColors.background,
      primary: AppColors.accentPrimary,
      secondary: AppColors.accentLight,
      error: AppColors.danger,
      onSurface: AppColors.textPrimary,
      onPrimary: AppColors.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: '.SF Pro Display',
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.title,
        headlineMedium: AppTextStyles.headline,
        titleMedium: AppTextStyles.subtitle,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodySecondary,
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.subtitle,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
