import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Бейдж формата: MP3/MP4/WAV.
/// Если [filled] — синий фон + белый текст. Иначе — тёмный фон + белый текст.
class FormatBadge extends StatelessWidget {
  const FormatBadge(this.label, {super.key, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMd,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: filled ? AppColors.accentPrimary : AppColors.iconButtonBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text(label.toUpperCase(), style: AppTextStyles.badge),
    );
  }
}
