import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';
import '../../app/theme/app_text_styles.dart';

/// Loading-модал (Image#2): чёрный overlay 50%, по центру:
/// квадрат 140×140 radius 42 #1C1C1C, под ним "Processing..." и подпись 60% white.
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
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppDimens.modalBoxSize,
              height: AppDimens.modalBoxSize,
              decoration: BoxDecoration(
                color: AppColors.modalBox,
                borderRadius: BorderRadius.circular(AppDimens.radius42),
              ),
              child: const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accentSolid,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space24),
            Text(title,
                style: AppTextStyles.processingTitle, textAlign: TextAlign.center),
            const SizedBox(height: AppDimens.space8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.processingSub,
            ),
          ],
        ),
      ),
    );
  }
}
