import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';
import 'app_icon.dart';

/// Карточка-источник Gallery / Files (Image#1).
/// 163.5×119, radius 24, gradient. Внутри:
///  • иконка-контейнер 48×48 (white, radius 12) сверху-слева;
///  • метка + chevron внизу-слева;
///  • декоративный размытый круг справа сверху.
class IconCardButton extends StatelessWidget {
  const IconCardButton({
    required this.label,
    required this.onTap,
    super.key,
    this.icon,
    this.iconAsset,
    this.chevronAsset = 'assets/images/icons/ic_chevron_right.png',
    this.backgroundDecorationAsset,
  })  : assert(icon != null || iconAsset != null,
            'Provide icon or iconAsset');

  final String label;
  final IconData? icon;
  final String? iconAsset;
  final String? chevronAsset;

  /// Большая полупрозрачная иконка-декорация в правом верхнем углу card
  /// (по Figma — копия image/folder icon, как watermark поверх gradient).
  final String? backgroundDecorationAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.iconCardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.radius24),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(AppDimens.radius24),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                // Большая полупрозрачная иконка-декорация в правом верхнем
                // углу card — повторяет основную иконку card (gallery/folder)
                // как watermark поверх gradient. По Figma на каждой card
                // есть такой ассет — обязательная декорация.
                if (backgroundDecorationAsset != null)
                  Positioned(
                    top: -16,
                    right: -32,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          backgroundDecorationAsset!,
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (BuildContext c, Object err,
                                  StackTrace? st) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: AppDimens.iconCardInnerBox,
                        height: AppDimens.iconCardInnerBox,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radius12),
                        ),
                        child: Center(
                          child: AppIcon(
                            assetPath: iconAsset,
                            fallback: icon,
                            size: 28,
                            color: AppColors.accentDeep,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: <Widget>[
                          Text(label, style: AppTextStyles.cardLabel),
                          const SizedBox(width: AppDimens.space4),
                          AppIcon(
                            assetPath: chevronAsset,
                            fallback: Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
