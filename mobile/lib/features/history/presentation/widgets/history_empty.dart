import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Image#1 (empty state): иконка микрофона с кругом + надпись.
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space2xl),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(60),
                  ),
                ),
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _MicWavePainter(),
                ),
                const Icon(
                  Icons.mic_rounded,
                  size: 56,
                  color: AppColors.accentPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space2xl),
          const Text(
            'Your History Is Empty',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppDimens.spaceSm),
          const Text(
            'To get started tap "Gallery" or "Files",\nor just insert link of YouTube video',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _MicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.3)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    const int bars = 24;
    final double step = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final double x = i * step + step / 2;
      final double normalized = (i / bars - 0.5).abs();
      final double h = (1 - normalized) * size.height * 0.4 + 4;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
