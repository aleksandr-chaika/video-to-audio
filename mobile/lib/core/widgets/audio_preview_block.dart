import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Preview-блок (Result/Crop): radius 32, white@5%.
/// Внутри:
/// 1) если есть `imagePath` (обложка) — Image.file;
/// 2) иначе — 3D-asset (по умолчанию music note);
/// 3) [showWaveformBackground]=true рисует горизонтальный waveform на фоне
///    (под иконкой ноты) — как в Crop-экране Figma.
class AudioPreviewBlock extends StatelessWidget {
  const AudioPreviewBlock({
    super.key,
    this.imagePath,
    this.placeholderAsset = 'assets/images/music_note_3d.png',
    this.placeholderIcon = Icons.music_note_rounded,
    this.height = AppDimens.previewIconOnlyHeight,
    this.bottomOverlay,
    this.showWaveformBackground = false,
  });

  final String? imagePath;
  final String? placeholderAsset;
  final IconData placeholderIcon;
  final double height;
  final Widget? bottomOverlay;
  final bool showWaveformBackground;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null && File(imagePath!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radius32),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(AppDimens.radius32),
          border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
        ),
        child: Stack(
          children: <Widget>[
            // Bg waveform (за нотой) — только в Crop screen
            if (showWaveformBackground && !hasImage)
              const Positioned.fill(
                child: _BackgroundWaveform(),
              ),
            Positioned.fill(
              child: hasImage
                  ? Image.file(File(imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: placeholderAsset != null
                            ? Image.asset(
                                placeholderAsset!,
                                fit: BoxFit.contain,
                                errorBuilder: (c, o, s) => Icon(
                                  placeholderIcon,
                                  size: 122,
                                  color: AppColors.accentSolid,
                                ),
                              )
                            : Icon(placeholderIcon,
                                size: 122, color: AppColors.accentSolid),
                      ),
                    ),
            ),
            if (bottomOverlay != null)
              Positioned(
                left: AppDimens.space14,
                right: AppDimens.space14,
                bottom: AppDimens.space14,
                child: bottomOverlay!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Декоративный waveform на фон — тонкие вертикальные палки, центрированные
/// по высоте контейнера, с псевдо-случайной амплитудой. Цвет — приглушённый
/// (white @ 0.18), чтобы 3D-нота поверх читалась как главный объект.
class _BackgroundWaveform extends StatelessWidget {
  const _BackgroundWaveform();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BgWavePainter());
  }
}

class _BgWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const int bars = 64;
    final double step = size.width / bars;
    final double centerY = size.height / 2;
    for (int i = 0; i < bars; i++) {
      final double x = i * step + step / 2;
      // Псевдослучайная высота с акцентом на середину/края (как в Figma)
      final double n1 = ((i * 9 + 13) % 17) / 17.0;
      final double n2 = ((i * 5 + 3) % 11) / 11.0;
      final double amp = (0.25 + n1 * 0.6 + n2 * 0.4).clamp(0.2, 1.0);
      final double h = size.height * 0.35 * amp;
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
