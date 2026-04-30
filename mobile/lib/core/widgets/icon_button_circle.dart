import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Header кнопка 38×38, radius 12. Default — white@10% bg + edge gradient stroke.
/// Может быть danger-вариантом (red@15% bg, red icon).
class IconButtonCircle extends StatelessWidget {
  const IconButtonCircle({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = AppDimens.headerButtonSize,
    this.background,
    this.iconColor = AppColors.textPrimary,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? background;
  final Color iconColor;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color bg = background ??
        (danger
            ? const Color(0x26F42727) // 15%
            : const Color(0x1AFFFFFF)); // 10%
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
            border: Border.all(
              color: const Color(0x0DFFFFFF),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Icon(icon,
                size: AppDimens.headerInnerIcon, color: color),
          ),
        ),
      ),
    );
  }
}
