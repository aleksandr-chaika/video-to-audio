import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import 'app_icon.dart';

/// Header кнопка 38×38, radius 12.
/// Default — white@10% bg + edge gradient stroke.
/// Может быть danger-вариантом (red@15% bg, red icon).
/// Принимает либо `iconAsset` (PNG из Figma), либо `icon` (Material IconData).
class IconButtonCircle extends StatelessWidget {
  const IconButtonCircle({
    required this.onPressed,
    super.key,
    this.icon,
    this.iconAsset,
    this.size = AppDimens.headerButtonSize,
    this.background,
    this.iconColor = AppColors.textPrimary,
    this.danger = false,
  }) : assert(icon != null || iconAsset != null,
            'Provide icon or iconAsset');

  final IconData? icon;
  final String? iconAsset;
  final VoidCallback onPressed;
  final double size;
  final Color? background;
  final Color iconColor;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color bg = background ??
        (danger
            ? const Color(0x26F42727)
            : const Color(0x1AFFFFFF));
    final Color color = danger ? AppColors.danger : iconColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radius12),
        onTap: onPressed,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimens.radius12),
            border: Border.all(color: const Color(0x0DFFFFFF), width: 0.5),
          ),
          child: Center(
            child: AppIcon(
              assetPath: iconAsset,
              fallback: icon,
              size: AppDimens.headerInnerIcon,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
