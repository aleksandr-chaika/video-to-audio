import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Синяя «карточка»-источник с иконкой в верхнем-левом углу и подписью + chevron.
/// Используется для Gallery / Files (Image#1).
class IconCardButton extends StatelessWidget {
  const IconCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radius2xl),
        onTap: onTap,
        child: Ink(
          height: AppDimens.iconCardHeight,
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppDimens.radius2xl),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.accentPrimary.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Center(child: icon),
                ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    Text(label, style: AppTextStyles.cardLabel),
                    const SizedBox(width: AppDimens.spaceXs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
