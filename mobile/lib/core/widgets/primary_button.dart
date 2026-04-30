import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Основная синяя градиент-кнопка (Save / Share / Submit).
/// Высота фиксирована (54), ширина — растянута контейнером.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = AppDimens.primaryButtonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    final Widget content = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.textPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: AppDimens.spaceSm),
              ],
              Text(label, style: AppTextStyles.button),
            ],
          );

    final BoxDecoration deco = BoxDecoration(
      gradient: enabled ? AppColors.accentGradient : null,
      color: enabled ? null : AppColors.iconButtonBg,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      boxShadow: enabled
          ? <BoxShadow>[
              BoxShadow(
                color: AppColors.accentPrimary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ]
          : null,
    );

    final Widget btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Ink(
          decoration: deco,
          height: height,
          child: Center(child: content),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
