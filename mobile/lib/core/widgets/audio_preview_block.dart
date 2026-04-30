import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimens.dart';

/// Preview-блок (Result/Crop): radius 32, white@5%.
/// Внутри:
/// 1) если есть `imagePath` (обложка) — Image.file;
/// 2) иначе — 3D-asset (по умолчанию music note);
/// 3) [showWaveformBackground]=true рисует горизонтальный waveform на фоне
///    (под иконкой ноты). Если [playing]=true — бары пульсируют синусом.
class AudioPreviewBlock extends StatefulWidget {
  const AudioPreviewBlock({
    super.key,
    this.imagePath,
    this.placeholderAsset = 'assets/images/music_note_3d.png',
    this.placeholderIcon = Icons.music_note_rounded,
    this.height = AppDimens.previewIconOnlyHeight,
    this.bottomOverlay,
    this.showWaveformBackground = false,
    this.noteSize = 150,
    this.playing = false,
  });

  final String? imagePath;
  final String? placeholderAsset;
  final IconData placeholderIcon;
  final double height;
  final Widget? bottomOverlay;
  final bool showWaveformBackground;

  /// Размер ноты (или Icon fallback). По умолчанию 150 (Crop), для Result — 190.
  final double noteSize;

  /// Когда true — waveform-фон оживает, бары пульсируют sin-волной.
  final bool playing;

  @override
  State<AudioPreviewBlock> createState() => _AudioPreviewBlockState();
}

class _AudioPreviewBlockState extends State<AudioPreviewBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant AudioPreviewBlock old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.playing && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        widget.imagePath != null && File(widget.imagePath!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radius32),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(AppDimens.radius32),
          border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
        ),
        child: Stack(
          children: <Widget>[
            // Bg waveform — за нотой
            if (widget.showWaveformBackground && !hasImage)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (BuildContext c, Widget? w) => CustomPaint(
                    painter: _BgWavePainter(
                      phase: _ctrl.value,
                      playing: widget.playing,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: hasImage
                  ? Image.file(File(widget.imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: RepaintBoundary(
                        child: SizedBox(
                          width: widget.noteSize,
                          height: widget.noteSize,
                          child: widget.placeholderAsset != null
                              ? Image.asset(
                                  widget.placeholderAsset!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, o, s) => Icon(
                                    widget.placeholderIcon,
                                    size: widget.noteSize * 0.8,
                                    color: AppColors.accentSolid,
                                  ),
                                )
                              : Icon(
                                  widget.placeholderIcon,
                                  size: widget.noteSize * 0.8,
                                  color: AppColors.accentSolid,
                                ),
                        ),
                      ),
                    ),
            ),
            if (widget.bottomOverlay != null)
              Positioned(
                left: AppDimens.space14,
                right: AppDimens.space14,
                bottom: AppDimens.space14,
                child: widget.bottomOverlay!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Декоративный waveform на фон. При [playing] амплитуда баров модулируется
/// синусом с фазовым сдвигом по позиции — выглядит как «бегущая» волна.
class _BgWavePainter extends CustomPainter {
  _BgWavePainter({required this.phase, required this.playing});

  final double phase; // 0..1
  final bool playing;

  static const int _bars = 64;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final double step = size.width / _bars;
    final double centerY = size.height / 2;
    for (int i = 0; i < _bars; i++) {
      final double x = i * step + step / 2;
      // Базовый псевдослучайный «силуэт» — стабильный от тика к тику.
      final double n1 = ((i * 9 + 13) % 17) / 17.0;
      final double n2 = ((i * 5 + 3) % 11) / 11.0;
      final double base = (0.25 + n1 * 0.6 + n2 * 0.4).clamp(0.2, 1.0);
      final double pulse = playing
          ? (0.6 +
              0.4 *
                  (0.5 +
                      0.5 *
                          math.sin(
                            phase * 2 * math.pi + i * 0.35,
                          )))
          : 1.0;
      final double amp = base * pulse;
      final double h = size.height * 0.35 * amp;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BgWavePainter old) =>
      old.phase != phase || old.playing != playing;
}
