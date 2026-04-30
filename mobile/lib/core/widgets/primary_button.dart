import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Primary CTA: 343×56, radius 20, gradient #6298FF→#1B63F8 + stroke white@20%→0%.
/// Используется для Save / Share / Convert.
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
                const SizedBox(width: AppDimens.space8),
              ],
              Text(label, style: AppTextStyles.button),
            ],
          );

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SizedBox(
        width: expand ? double.infinity : null,
        height: height,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppDimens.radius20),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimens.radius20),
              onTap: enabled ? onPressed : null,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radius20),
                          border: const _GradientBorder(),
                        ),
                      ),
                    ),
                  ),
                  Center(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBorder extends Border {
  const _GradientBorder();

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final Paint paint = Paint()
      ..shader = AppColors.strokeAccentGradient.createShader(rect)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final RRect rrect = (borderRadius ??
            BorderRadius.circular(AppDimens.radius20))
        .toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }
}
