import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Большой preview-блок: либо обложка/кадр (Image), либо иконка ноты,
/// либо иконка камеры — общий между Result и Crop экранами (Image#3, Image#4).
class AudioPreviewBlock extends StatelessWidget {
  const AudioPreviewBlock({
    super.key,
    this.imagePath,
    this.placeholderIcon = Icons.music_note_rounded,
    this.height = AppDimens.previewHeight,
    this.showWaveformBackground = true,
  });

  final String? imagePath;
  final IconData placeholderIcon;
  final double height;
  final bool showWaveformBackground;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null && File(imagePath!).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radius2xl),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(color: AppColors.surfaceDark),
        child: hasImage
            ? Image.file(File(imagePath!), fit: BoxFit.cover)
            : Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (showWaveformBackground)
                    Positioned.fill(
                      child: CustomPaint(painter: _WaveformBackground()),
                    ),
                  Icon(placeholderIcon,
                      size: 96, color: AppColors.accentPrimary),
                ],
              ),
      ),
    );
  }
}

class _WaveformBackground extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const int bars = 60;
    final double step = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final double normalized = (i / bars - 0.5).abs();
      final double amplitude = (1 - normalized) * (size.height * 0.32);
      final double x = i * step + step / 2;
      final double yCenter = size.height / 2;
      final double pseudoRandom = (i * 11 % 7) / 7.0;
      final double h = amplitude * (0.4 + pseudoRandom * 0.6);
      canvas.drawLine(
        Offset(x, yCenter - h),
        Offset(x, yCenter + h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
