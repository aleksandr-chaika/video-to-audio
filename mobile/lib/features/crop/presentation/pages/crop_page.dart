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
    _player.playing ? _player.pause() : _player.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          Positioned(
            left: -232,
            top: -617,
            child: Container(
              width: 839,
              height: 839,
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
            IconButtonCircle(icon: Icons.close_rounded, onPressed: onClose),
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
            height: AppDimens.previewIconOnlyHeight,
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
            color: const Color(0x1AFFFFFF),
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
      height: AppDimens.cropTrimmerHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radius20),
        border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
      ),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: AppDimens.playerControlSize,
              height: AppDimens.playerControlSize,
              decoration: BoxDecoration(
                color: AppColors.accentSolid.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.accentSolid,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space8),
          Expanded(
            child: SizedBox(
              height: AppDimens.cropTrimmerHeight - 14,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(painter: _WaveformPainter()),
                  ),
                  RangeSlider(
                    min: 0,
                    max: state.total.inMilliseconds
                        .toDouble()
                        .clamp(1, double.infinity),
                    values: RangeValues(
                      state.start.inMilliseconds.toDouble(),
                      state.end.inMilliseconds.toDouble(),
                    ),
                    activeColor: AppColors.accentSolid,
                    inactiveColor:
                        AppColors.accentSolid.withValues(alpha: 0.18),
                    onChanged: (RangeValues v) {
                      context.read<CropBloc>().add(CropRangeChanged(
                            start:
                                Duration(milliseconds: v.start.toInt()),
                            end: Duration(milliseconds: v.end.toInt()),
                          ));
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
      ..color = AppColors.accentSolid.withValues(alpha: 0.55)
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
