import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/audio_preview_block.dart';
import '../../../../core/widgets/format_badge.dart';
import '../../../../core/widgets/icon_button_circle.dart';
import '../../../../core/widgets/primary_button.dart';
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
    _player.playerStateStream.listen((PlayerState s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<CropBloc, CropState>(
          listener: (BuildContext context, CropState state) {
            if (state is CropSaved) {
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
                _AppBar(onClose: () => context.pop()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceLg,
                    ),
                    child: switch (state) {
                      CropInitial() ||
                      CropSaving() ||
                      CropSaved() =>
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentPrimary,
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
                    AppDimens.spaceLg,
                    AppDimens.spaceLg,
                    AppDimens.spaceLg,
                    AppDimens.space2xl,
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
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spaceLg,
        AppDimens.spaceMd,
        AppDimens.spaceLg,
        AppDimens.spaceLg,
      ),
      child: Row(
        children: <Widget>[
          IconButtonCircle(icon: Icons.close_rounded, onPressed: onClose),
          const Expanded(
            child: Center(
              child: Text('Result', style: AppTextStyles.subtitle),
            ),
          ),
          const SizedBox(width: AppDimens.iconButtonSize),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceLg),
      child: Column(
        children: <Widget>[
          const AudioPreviewBlock(),
          const SizedBox(height: AppDimens.spaceMd),
          _FormatRow(duration: state.total),
          const SizedBox(height: AppDimens.space3xl),
          _RangeReadout(state: state),
          const SizedBox(height: AppDimens.spaceLg),
          _Trimmer(state: state, playing: playing, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.duration});
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const FormatBadge('MP3'),
        const SizedBox(width: AppDimens.spaceSm),
        const Icon(Icons.arrow_forward_rounded,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppDimens.spaceSm),
        const FormatBadge('WAV', filled: true),
        const Spacer(),
        Text(
          DurationFormatter.format(duration),
          style: AppTextStyles.duration,
        ),
      ],
    );
  }
}

class _RangeReadout extends StatelessWidget {
  const _RangeReadout({required this.state});
  final CropReady state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceLg,
        vertical: AppDimens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTextStyles.duration.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          children: <InlineSpan>[
            TextSpan(text: DurationFormatter.format(state.start)),
            const TextSpan(text: '  –  ',
                style: TextStyle(color: AppColors.textSecondary)),
            TextSpan(
              text: DurationFormatter.format(state.end),
              style: const TextStyle(color: AppColors.accentPrimary),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: DurationFormatter.format(state.total),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Trimmer extends StatelessWidget {
  const _Trimmer({
    required this.state,
    required this.playing,
    required this.onToggle,
  });

  final CropReady state;
  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                playing ? Icons.pause : Icons.play_arrow,
                color: AppColors.accentPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.spaceSm),
          Expanded(
            child: SizedBox(
              height: AppDimens.cropTrimmerHeight,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(painter: _WaveformPainter()),
                  ),
                  RangeSlider(
                    min: 0,
                    max: state.total.inMilliseconds.toDouble().clamp(1, double.infinity),
                    values: RangeValues(
                      state.start.inMilliseconds.toDouble(),
                      state.end.inMilliseconds.toDouble(),
                    ),
                    activeColor: AppColors.accentPrimary,
                    inactiveColor:
                        AppColors.accentPrimary.withValues(alpha: 0.18),
                    onChanged: (RangeValues v) {
                      context.read<CropBloc>().add(
                            CropRangeChanged(
                              start: Duration(milliseconds: v.start.toInt()),
                              end: Duration(milliseconds: v.end.toInt()),
                            ),
                          );
                    },
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

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const int bars = 80;
    final double step = size.width / bars;
    final double centerY = size.height / 2;
    for (int i = 0; i < bars; i++) {
      final double x = i * step + step / 2;
      final double pseudo = ((i * 17 + 3) % 11) / 11.0;
      final double h = (size.height * 0.4) * (0.3 + pseudo * 0.7);
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
