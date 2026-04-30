import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';

/// Empty history state — Image#13 reference (Figma).
/// Rounded square 110×110 radius 24 #14191F.
/// Внутри card сверху — тонкая waveform-полоса, ниже — синий микрофон.
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space24),
      child: Column(
        children: <Widget>[
          // Card 110×110 с waveform сверху и mic-icon снизу.
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppDimens.radius24),
            ),
            child: Stack(
              children: <Widget>[
                // Waveform-полоса в верхней четверти card.
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  height: 18,
                  child: CustomPaint(painter: _MicWavePainter()),
                ),
                // Mic-icon — занимает нижние ~3/4 card.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Center(
                    child: Image.asset(
                      'assets/images/mic_3d.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                      errorBuilder:
                          (BuildContext c, Object err, StackTrace? st) {
                        if (kDebugMode) {
                          debugPrint('mic_3d.png load failed: $err');
                        }
                        return const Icon(
                          Icons.mic_rounded,
                          size: 56,
                          color: AppColors.accentSolid,
                        );
                      },
                    ),
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

/// Тонкая audio-визуализация — горизонтальные бары переменной высоты,
/// рисуются по всей ширине canvas. Симулирует пик-уровни записи.
class _MicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accentSolid.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const int bars = 32;
    final double step = size.width / bars;
    final double centerY = size.height / 2;
    for (int i = 0; i < bars; i++) {
      final double x = i * step + step / 2;
      // Псевдо-случайная амплитуда (стабильная между рендерами).
      final double n1 = ((i * 11 + 3) % 17) / 17.0;
      final double n2 = ((i * 7 + 5) % 13) / 13.0;
      final double amp = (0.25 + n1 * 0.55 + n2 * 0.4).clamp(0.15, 1.0);
      final double h = size.height * amp;
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
