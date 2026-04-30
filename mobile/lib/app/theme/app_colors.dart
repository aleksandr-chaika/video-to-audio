import 'package:flutter/material.dart';

/// Цветовые токены MP3 Craft. Источник — Figma (см. docs/design-tokens.md).
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF111111);
  static const Color surfaceDark = Color(0xFF14191F);
  static const Color surfaceCard = Color(0xFF14191F);
  static const Color modalBox = Color(0xFF1C1C1C);

  // Accent
  static const Color accentGradientTop = Color(0xFF6298FF);
  static const Color accentGradientBottom = Color(0xFF1B63F8);
  static const Color accentSolid = Color(0xFF3F7EFB);
  static const Color accentDeep = Color(0xFF1B63F8);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF6298FF), Color(0xFF1B63F8)],
  );

  /// Тонкая обводка (white@20% → 0%) поверх синих градиентов.
  static const LinearGradient strokeAccentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x33FFFFFF), Color(0x00FFFFFF)],
  );

  /// Тонкая обводка (white@5% → 0%) для тёмных surface.
  static const LinearGradient strokeSurfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x0DFFFFFF), Color(0x00FFFFFF)],
  );

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF); // 70%
  static const Color textTertiary = Color(0x99FFFFFF); // 60%
  static const Color textMuted = Color(0x4DFFFFFF); // 30%
  static const Color textFaded = Color(0x40FFFFFF); // 25%

  // Status / utility
  static const Color danger = Color(0xFFF42727);
  static const Color youtubeRed = Color(0xFFFF0000);
  static const Color success = Color(0xFF34C759);
}
