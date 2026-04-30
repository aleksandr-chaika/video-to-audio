import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Круглая иконка-кнопка (settings, close, delete).
class IconButtonCircle extends StatelessWidget {
  const IconButtonCircle({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = AppDimens.iconButtonSize,
    this.background = AppColors.iconButtonBg,
    this.iconColor = AppColors.textPrimary,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        onTap: onPressed,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          ),
          child: Center(child: Icon(icon, size: 20, color: iconColor)),
        ),
      ),
    );
  }
}
