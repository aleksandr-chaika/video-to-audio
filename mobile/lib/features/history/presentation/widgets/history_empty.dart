import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// Empty history state — Image#1, второй фрейм.
/// Фигма: rounded square 110×110 radius 24 #14191F + 3D-микрофон + waveform по сторонам.
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space24),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Waveform: уходит за пределы container'а (полная ширина)
                SizedBox(
                  width: 220,
                  height: 60,
                  child: CustomPaint(painter: _MicWavePainter()),
                ),
                // Dark rounded square 110×110, radius 24
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(AppDimens.radius24),
                  ),
                ),
                // 3D-микрофон
                Image.asset(
                  'assets/images/mic_3d.png',
                  width: 78,
                  height: 78,
                  fit: BoxFit.contain,
                  errorBuilder: (c, o, s) => const Icon(
                    Icons.mic_rounded,
                    size: 56,
                    color: AppColors.accentSolid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space20),
          Text(
            'Your History Is Empty',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 21.6 / 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            'To get started tap “Gallery” or “Files”,\nor just insert link of YouTube video',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 18.2 / 13,
              color: AppColors.textPrimary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Waveform-bars: рисуются на 220×60, но 6 центральных скрыты (там mic 110×110).
class _MicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accentSolid.withValues(alpha: 0.45)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double centerY = size.height / 2;
    const int bars = 26;
    final double step = size.width / bars;
    // Скрываем центральные ~10 баров (где dark square + mic)
    const int hideFrom = 8;
    const int hideTo = 17;
    for (int i = 0; i < bars; i++) {
      if (i >= hideFrom && i <= hideTo) continue;
      final double x = i * step + step / 2;
      final double normalized = (i / bars - 0.5).abs();
      final double pseudo = ((i * 7 + 3) % 5) / 5.0;
      final double h =
          (1 - normalized) * size.height * 0.8 * (0.4 + pseudo * 0.6) + 4;
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
