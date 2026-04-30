import 'package:flutter/material.dart';

/// Цветовые токены MP3 Craft (извлечены из мокапов Image #1–#4).
class AppColors {
  AppColors._();

  // Background
  static const Color background = Color(0xFF0A0E1A);
  static const Color surfaceDark = Color(0xFF11182B);
  static const Color surfaceCard = Color(0xFF1A2238);
  static const Color appBarBlue = Color(0xFF0E1A33);
  static const Color appBarBlueEnd = Color(0xFF1B2D5A);

  // Accent gradient (синие карточки и кнопки)
  static const Color accentLight = Color(0xFF6FA9FF);
  static const Color accentPrimary = Color(0xFF3B82F6);
  static const Color accentDeep = Color(0xFF2256D6);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF7CB6FF), Color(0xFF3679FF), Color(0xFF1E5BD9)],
    stops: <double>[0.0, 0.55, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF8FBEFF), Color(0xFF3F86FF), Color(0xFF1E54C9)],
    stops: <double>[0.0, 0.5, 1.0],
  );

  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF1F3A6E), Color(0xFF0E1A33)],
  );

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E97A6);
  static const Color textMuted = Color(0xFF5A6577);

  // Status
  static const Color danger = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);

  // Semantic
  static const Color divider = Color(0xFF1F2A45);
  static const Color iconButtonBg = Color(0xFF20283C);
}
