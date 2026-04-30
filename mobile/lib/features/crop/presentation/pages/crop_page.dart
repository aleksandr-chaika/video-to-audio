import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/widgets/audio_preview_block.dart';
import '../../../../core/widgets/format_badge.dart';
import '../../../../core/widgets/icon_button_circle.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../history/domain/entities/history_item.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../bloc/crop_bloc.dart';

/// Image#4 — Crop Audio.
class CropPage extends StatefulWidget {
  const CropPage({
    required this.sourcePath,
    required this.totalMs,
    super.key,
  });
  final String sourcePath;
  final int totalMs;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  late final AudioPlayer _player;
  final List<StreamSubscription<Object?>> _subs = <StreamSubscription<Object?>>[];
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setFilePath(widget.sourcePath).then((Duration? d) {
      if (!mounted) return;
      final Duration total =
          d ?? Duration(milliseconds: widget.totalMs.clamp(1, 1 << 31));
      context
          .read<CropBloc>()
          .add(CropLoaded(sourcePath: widget.sourcePath, total: total));
    });
    _subs.add(_player.playerStateStream.listen((PlayerState s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    }));
  }

  @override
  void dispose() {
    for (final StreamSubscription<Object?> s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  void _toggle() {
    _player.playing ? _player.pause() : _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          Positioned(
            left: AppDimens.ambientEllipseLeft,
            top: AppDimens.ambientEllipseTop,
            child: Container(
              width: AppDimens.ambientEllipseSize,
              height: AppDimens.ambientEllipseSize,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.accentGradientTop,
                    AppColors.accentGradientBottom,
                    Color(0x00000000),
                  ],
                  stops: <double>[0.0, 0.6, 1.0],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: BlocConsumer<CropBloc, CropState>(
              listener: (BuildContext context, CropState state) {
                if (state is CropSaved) {
                  // Сохраняем cropped результат в History — иначе после
                  // закрытия Result он пропадает из истории.
                  context.read<HistoryBloc>().add(
                        HistoryItemAdded(
                          HistoryItem(
                            id: null,
                            sourceType: SourceType.local,
                            sourceFormat: SourceFormat.wav,
                            outputFormat: SourceFormat.wav,
                            filePath: state.outputPath,
                            durationMs: state.duration.inMilliseconds,
                            createdAt: DateTime.now(),
                            title: FileUtils.basenameWithoutExt(
                                state.outputPath),
                          ),
                        ),
                      );
                  context.go('/result', extra: <String, Object?>{
                    'path': state.outputPath,
                    'durationMs': state.duration.inMilliseconds,
                    'sourceFormat': 'wav',
                    'title': 'Cropped',
                  });
                } else if (state is CropError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              builder: (BuildContext context, CropState state) {
                return Column(
                  children: <Widget>[
                    _CropAppBar(onClose: () => context.pop()),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimens.space16),
                        child: switch (state) {
                          CropInitial() ||
                          CropSaving() ||
                          CropSaved() =>
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accentSolid,
                              ),
                            ),
                          CropReady() => _CropBody(
                              state: state,
                              playing: _playing,
                              onToggle: _toggle,
                            ),
                          CropError(:final CropReady previous) => _CropBody(
                              state: previous,
                              playing: _playing,
                              onToggle: _toggle,
                            ),
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.space16,
                        AppDimens.space16,
                        AppDimens.space16,
                        AppDimens.space24,
                      ),
                      child: PrimaryButton(
                        label: 'Save',
                        loading: state is CropSaving,
                        onPressed: state is CropReady
                            ? () => context
                                .read<CropBloc>()
                                .add(const CropSaveRequested())
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CropAppBar extends StatelessWidget {
  const _CropAppBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.appBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
        child: Row(
          children: <Widget>[
            IconButtonCircle(
              icon: Icons.close_rounded,
              iconAsset: 'assets/images/icons/ic_close.png',
              onPressed: onClose,
            ),
            Expanded(
              child: Center(
                child: Text('Result', style: AppTextStyles.appBarTitle),
              ),
            ),
            const SizedBox(width: AppDimens.headerButtonSize),
          ],
        ),
      ),
    );
  }
}

class _CropBody extends StatelessWidget {
  const _CropBody({
    required this.state,
    required this.playing,
    required this.onToggle,
  });
  final CropReady state;
  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space14),
      child: Column(
        children: <Widget>[
          AudioPreviewBlock(
            height: 280,
            showWaveformBackground: true,
            bottomOverlay: _PreviewBottomRow(duration: state.total),
          ),
          const SizedBox(height: AppDimens.space24),
          _RangePill(state: state),
          const SizedBox(height: AppDimens.space14),
          _Trimmer(state: state, playing: playing, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _PreviewBottomRow extends StatelessWidget {
  const _PreviewBottomRow({required this.duration});
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const FormatBadge('MP3'),
        const SizedBox(width: AppDimens.space8),
        const Icon(Icons.arrow_forward_rounded,
            size: 16, color: AppColors.textPrimary),
        const SizedBox(width: AppDimens.space8),
        const FormatBadge('WAV', filled: true),
        const Spacer(),
        Container(
          height: AppDimens.formatPillHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceOverlay10,
            borderRadius: BorderRadius.circular(AppDimens.radius16),
          ),
          child: Text(
            DurationFormatter.format(duration),
            style: AppTextStyles.formatBadge,
          ),
        ),
      ],
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({required this.state});
  final CropReady state;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radius24),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.duration,
          children: <InlineSpan>[
            TextSpan(text: DurationFormatter.format(state.start)),
            const TextSpan(text: '  -  ',
                style: TextStyle(color: AppColors.textPrimary)),
            TextSpan(
              text: DurationFormatter.format(state.end),
              style: const TextStyle(color: AppColors.accentSolid),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: DurationFormatter.format(state.total),
              style: const TextStyle(color: AppColors.textFaded),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crop trimmer — кастомный (Image #12 Figma):
///  • круглая pause-кнопка слева, отдельно от waveform-области
///  • dim waveform на всю ширину снаружи рамки
///  • голубая прямоугольная рамка с rounded corners вокруг выделенного диапазона
///  • bright waveform внутри рамки на синем фоне
///  • две вертикальные белые палочки-ручки по краям рамки — drag для start/end
///  • drag по самой рамке (между ручками) — двигает диапазон целиком
class _Trimmer extends StatelessWidget {
  const _Trimmer({
    required this.state,
    required this.playing,
    required this.onToggle,
  });

  final CropReady state;
  final bool playing;
  final VoidCallback onToggle;

  static const double _handleWidth = 22;
  static const double _handleBarWidth = 2.5;
  static const double _trimmerHeight = 80;
  static const double _waveformHeight = 56;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _trimmerHeight,
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceOverlay05, width: 1),
              ),
              child: Center(
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.accentSolid,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space12),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints c) {
                final double trackWidth = c.maxWidth;
                return _TrimmerTrack(
                  width: trackWidth,
                  height: _trimmerHeight,
                  waveformHeight: _waveformHeight,
                  handleWidth: _handleWidth,
                  handleBarWidth: _handleBarWidth,
                  state: state,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrimmerTrack extends StatelessWidget {
  const _TrimmerTrack({
    required this.width,
    required this.height,
    required this.waveformHeight,
    required this.handleWidth,
    required this.handleBarWidth,
    required this.state,
  });

  final double width;
  final double height;
  final double waveformHeight;
  final double handleWidth;
  final double handleBarWidth;
  final CropReady state;

  static const int _bars = 64;

  double _msToX(int ms) {
    final int total = state.total.inMilliseconds.clamp(1, 1 << 31);
    return (ms / total) * width;
  }

  @override
  Widget build(BuildContext context) {
    final double startX = _msToX(state.start.inMilliseconds);
    final double endX = _msToX(state.end.inMilliseconds);
    final double minRangeWidth = handleWidth * 2 + 8;

    void emitChange(Duration s, Duration e) {
      context.read<CropBloc>().add(CropRangeChanged(start: s, end: e));
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Dim waveform на всю ширину
          Positioned(
            left: 0,
            right: 0,
            top: (height - waveformHeight) / 2,
            height: waveformHeight,
            child: CustomPaint(
              painter: _WaveformPainter(
                bars: _bars,
                color: AppColors.surfaceOverlay25,
              ),
            ),
          ),
          // Голубая рамка с яркой waveform внутри
          Positioned(
            left: startX,
            top: 0,
            width: (endX - startX).clamp(minRangeWidth, double.infinity),
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (DragUpdateDetails d) {
                final int curStart = state.start.inMilliseconds;
                final int curEnd = state.end.inMilliseconds;
                final int totalMs = state.total.inMilliseconds;
                final double dxMs =
                    (d.delta.dx / width) * totalMs;
                int newStart = curStart + dxMs.round();
                int newEnd = curEnd + dxMs.round();
                if (newStart < 0) {
                  newEnd -= newStart;
                  newStart = 0;
                }
                if (newEnd > totalMs) {
                  newStart -= (newEnd - totalMs);
                  newEnd = totalMs;
                }
                emitChange(
                  Duration(milliseconds: newStart),
                  Duration(milliseconds: newEnd),
                );
              },
              child: Stack(
                children: <Widget>[
                  // Синий фон рамки
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.accentSolid,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radius16),
                      ),
                    ),
                  ),
                  // Bright waveform внутри
                  Positioned(
                    left: handleWidth,
                    right: handleWidth,
                    top: (height - waveformHeight) / 2,
                    height: waveformHeight,
                    child: ClipRect(
                      child: CustomPaint(
                        painter: _WaveformPainter(
                          bars: _bars,
                          color: Colors.white,
                          // Совпадение фаз с dim waveform — рисуем относительно
                          // полной ширины, но в clip-окне только часть.
                          totalWidth: width,
                          xOffset: -(startX + handleWidth),
                        ),
                      ),
                    ),
                  ),
                  // Левая палочка-ручка
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: handleWidth,
                    child: _Handle(
                      barWidth: handleBarWidth,
                      onDrag: (double dx) {
                        final int totalMs = state.total.inMilliseconds;
                        final double dxMs = (dx / width) * totalMs;
                        int newStart =
                            state.start.inMilliseconds + dxMs.round();
                        final int maxStart = state.end.inMilliseconds -
                            ((minRangeWidth / width) * totalMs).round();
                        newStart = newStart.clamp(0, maxStart);
                        emitChange(
                          Duration(milliseconds: newStart),
                          state.end,
                        );
                      },
                    ),
                  ),
                  // Правая палочка-ручка
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: handleWidth,
                    child: _Handle(
                      barWidth: handleBarWidth,
                      onDrag: (double dx) {
                        final int totalMs = state.total.inMilliseconds;
                        final double dxMs = (dx / width) * totalMs;
                        int newEnd =
                            state.end.inMilliseconds + dxMs.round();
                        final int minEnd = state.start.inMilliseconds +
                            ((minRangeWidth / width) * totalMs).round();
                        newEnd = newEnd.clamp(minEnd, totalMs);
                        emitChange(
                          state.start,
                          Duration(milliseconds: newEnd),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Вертикальная палочка-ручка (handle) — drag по горизонтали.
class _Handle extends StatelessWidget {
  const _Handle({required this.barWidth, required this.onDrag});
  final double barWidth;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (DragUpdateDetails d) => onDrag(d.delta.dx),
      child: Center(
        child: Container(
          width: barWidth,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(barWidth / 2),
          ),
        ),
      ),
    );
  }
}

/// Универсальный waveform-painter с псевдо-случайной амплитудой и стабильным
/// seed (одинаковая фаза для dim/bright рендеров → совпадают визуально).
class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.color,
    this.totalWidth,
    this.xOffset = 0,
  });

  final int bars;
  final Color color;

  /// Если задано — рисуем bars относительно totalWidth, а xOffset сдвигает.
  /// Используется для bright waveform внутри ClipRect — чтобы фазы баров
  /// совпали с dim waveform за пределами рамки.
  final double? totalWidth;
  final double xOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final double w = totalWidth ?? size.width;
    final double step = w / bars;
    final double centerY = size.height / 2;
    for (int i = 0; i < bars; i++) {
      final double x = i * step + step / 2 + xOffset;
      if (x < -4 || x > size.width + 4) continue;
      final double n1 = ((i * 9 + 13) % 17) / 17.0;
      final double n2 = ((i * 5 + 3) % 11) / 11.0;
      final double amp = (0.25 + n1 * 0.5 + n2 * 0.45).clamp(0.2, 1.0);
      final double h = size.height * 0.85 * amp;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.bars != bars ||
      old.color != color ||
      old.totalWidth != totalWidth ||
      old.xOffset != xOffset;
}
