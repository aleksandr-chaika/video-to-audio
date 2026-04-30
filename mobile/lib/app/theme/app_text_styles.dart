import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Типографика: Inter (Google Fonts). Точные размеры/lh/letter spacing — из Figma.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    Color color = AppColors.textPrimary,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height / fontSize,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Display "Craft" / 28 ExtraBold
  static TextStyle display = _inter(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 33.6,
  );

  // AppBar title 24 ExtraBold ("Result", "Convert Files")
  static TextStyle appBarTitle = _inter(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 28.8,
  );

  // Subtitle 16 Medium 70% under hero
  static TextStyle subtitle = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 20.8,
    color: AppColors.textSecondary,
  );

  // Card label 18 SemiBold (Gallery / Files)
  static TextStyle cardLabel = _inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 23.4,
    letterSpacing: -0.36,
  );

  // Section title 16 SemiBold (History / Choose Convertion Format)
  static TextStyle sectionTitle = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 17.6,
    letterSpacing: -0.32,
  );

  // Primary button 16 SemiBold
  static TextStyle button = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 17.6,
    letterSpacing: -0.32,
  );

  // Body 16 Medium ("Paste your link" placeholder)
  static TextStyle body = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 19.2,
  );

  // Format pill large 14 Medium (in Result preview)
  static TextStyle formatBadge = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 16.8,
  );

  // Format pill small 12 Medium (in History card)
  static TextStyle formatBadgeSm = _inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 14.4,
  );

  // Duration 13 Medium (crop trimmer "03:56")
  static TextStyle duration = _inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 16.9,
  );

  // Processing modal title
  static TextStyle processingTitle = _inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 28.8,
    letterSpacing: -0.48,
  );

  // Processing modal subtitle (white@60%)
  static TextStyle processingSub = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 19.2,
    color: AppColors.textTertiary,
  );

  // Status bar "9:41"
  static const TextStyle statusBar = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 22 / 17,
    letterSpacing: -0.408,
    color: AppColors.textPrimary,
  );
}
