import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Empty history state — Image#1, второй фрейм.
/// Большой круг #14191F + 3D-микрофон в центре + "wave bars" по бокам.
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space24),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 130,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceCard,
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _MicWavePainter())),
                const Icon(Icons.mic_rounded,
                    size: 56, color: AppColors.accentSolid),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space20),
          const Text(
            'Your History Is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'To get started tap "Gallery" or "Files",\nor just insert link of YouTube video',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
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
      ..color = AppColors.accentSolid.withValues(alpha: 0.32)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    const int bars = 18;
    final double step = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final double x = i * step + step / 2;
      // Hide center 6 bars (occupied by mic icon)
      if (i >= 6 && i <= 11) continue;
      final double normalized = (i / bars - 0.5).abs();
      final double h = (1 - normalized) * size.height * 0.36 + 6;
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
