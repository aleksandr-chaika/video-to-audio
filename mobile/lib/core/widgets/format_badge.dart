import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Format pill MP3 / MP4 / WAV.
/// Большая (Result preview): h=25, label 14, radius 16, white@10% / accent gradient.
/// Маленькая (history): h=22, label 12, radius 16, white@10%.
class FormatBadge extends StatelessWidget {
  const FormatBadge(
    this.label, {
    super.key,
    this.filled = false,
    this.size = FormatBadgeSize.large,
  });

  final String label;
  final bool filled;
  final FormatBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final bool isSmall = size == FormatBadgeSize.small;
    return Container(
      height: isSmall
          ? AppDimens.formatPillSmallHeight
          : AppDimens.formatPillHeight,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 7 : 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? null : const Color(0x1AFFFFFF), // 10%
        gradient: filled ? AppColors.accentGradient : null,
        borderRadius: BorderRadius.circular(AppDimens.radius16),
      ),
      child: Text(
        label.toUpperCase(),
        style:
            isSmall ? AppTextStyles.formatBadgeSm : AppTextStyles.formatBadge,
      ),
    );
  }
}

enum FormatBadgeSize { small, large }
