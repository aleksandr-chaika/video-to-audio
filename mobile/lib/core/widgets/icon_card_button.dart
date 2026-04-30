import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Карточка-источник Gallery / Files (Image#1).
/// 163.5×119, radius 24, gradient. Внутри: иконка-контейнер 48×48 (white, radius 12)
/// сверху-слева, метка + chevron внизу-слева, декоративный размытый круг справа.
class IconCardButton extends StatelessWidget {
  const IconCardButton({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
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
                // декоративный полупрозрачный круг справа сверху
                Positioned(
                  top: -120,
                  right: -120,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x1AFFFFFF),
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
                        child: Icon(icon,
                            size: 26, color: AppColors.accentDeep),
                      ),
                      const Spacer(),
                      Row(
                        children: <Widget>[
                          Text(label, style: AppTextStyles.cardLabel),
                          const SizedBox(width: AppDimens.space4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
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
