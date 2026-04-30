import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Полноэкранный модал «Processing…» (Image #2).
/// Затемняет underlying экран, по центру — карточка с CircularProgress + текст.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    this.title = 'Processing...',
    this.subtitle = 'Please stay on this screen.\nTime depends on audio length',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: 0.55),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppDimens.radius2xl),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space2xl),
              Text(title, style: AppTextStyles.subtitle),
              const SizedBox(height: AppDimens.spaceSm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
