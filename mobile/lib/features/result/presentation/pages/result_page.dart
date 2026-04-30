import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimens.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../core/widgets/audio_preview_block.dart';
import '../../../../core/widgets/format_badge.dart';
import '../../../../core/widgets/icon_button_circle.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../history/domain/entities/history_item.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../domain/entities/result_payload.dart';

/// Image#3 — экран Result.
class ResultPage extends StatefulWidget {
  const ResultPage({required this.payload, super.key});

  final ResultPayload payload;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _setup();
  }

  Future<void> _setup() async {
    final Duration? duration = await _player.setFilePath(widget.payload.filePath);
    if (!mounted) return;
    setState(() {
      _duration = duration ??
          (widget.payload.durationMs > 0
              ? widget.payload.duration
              : Duration.zero);
    });
    _player.positionStream.listen((Duration p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
    _player.playerStateStream.listen((PlayerState s) {
      if (!mounted) return;
      if (s.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles(<XFile>[XFile(widget.payload.filePath)]);
  }

  void _delete() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: const Text('Delete?', style: AppTextStyles.subtitle),
        content: const Text(
          'Запись будет удалена из истории и с устройства.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Удаляем по file_path.
              final HistoryState state = context.read<HistoryBloc>().state;
              if (state is HistoryLoaded) {
                final HistoryItem? item = state.items
                    .where((HistoryItem h) =>
                        h.filePath == widget.payload.filePath)
                    .firstOrNull;
                if (item?.id != null) {
                  context
                      .read<HistoryBloc>()
                      .add(HistoryItemDeleted(item!.id!));
                }
              }
              context.go('/');
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResultPayload p = widget.payload;
    final Duration remaining = _duration - _position;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _AppBar(onClose: () => context.go('/'), onDelete: _delete),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimens.spaceLg),
                child: Column(
                  children: <Widget>[
                    AudioPreviewBlock(
                      imagePath: p.thumbnailPath,
                      placeholderIcon: p.sourceFormat == SourceFormat.mp4
                          ? Icons.videocam_rounded
                          : Icons.music_note_rounded,
                    ),
                    const SizedBox(height: AppDimens.spaceMd),
                    _FormatRow(
                      sourceLabel: p.sourceFormat.label,
                      duration: _duration,
                    ),
                    const SizedBox(height: AppDimens.space2xl),
                    _CropAudioButton(onTap: () {
                      context.push('/crop', extra: <String, Object?>{
                        'path': p.filePath,
                        'durationMs': _duration.inMilliseconds,
                      });
                    }),
                    const SizedBox(height: AppDimens.spaceLg),
                    _PlayerBar(
                      playing: _player.playing,
                      position: _position,
                      remaining: remaining,
                      duration: _duration,
                      onToggle: _togglePlay,
                      onSeek: (Duration d) => _player.seek(d),
                    ),
                  ],
                ),
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
                label: 'Share',
                icon: Icons.ios_share_rounded,
                onPressed: _share,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onClose, required this.onDelete});

  final VoidCallback onClose;
  final VoidCallback onDelete;

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
          IconButtonCircle(
            icon: Icons.delete_outline_rounded,
            background: AppColors.danger.withValues(alpha: 0.18),
            iconColor: AppColors.danger,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.sourceLabel, required this.duration});

  final String sourceLabel;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FormatBadge(sourceLabel),
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

class _CropAudioButton extends StatelessWidget {
  const _CropAudioButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: onTap,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.45),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.crop_rounded,
                    color: AppColors.accentPrimary, size: 18),
                const SizedBox(width: AppDimens.spaceSm),
                Text(
                  'Crop Audio',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.playing,
    required this.position,
    required this.remaining,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
  });

  final bool playing;
  final Duration position;
  final Duration remaining;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final double total = duration.inMilliseconds.clamp(1, 1 << 31).toDouble();
    final double pos = position.inMilliseconds.clamp(0, total).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceMd,
        vertical: AppDimens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            iconSize: 32,
            color: AppColors.accentPrimary,
            icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
            onPressed: onToggle,
          ),
          Text(DurationFormatter.format(position),
              style: AppTextStyles.duration),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: AppColors.accentPrimary,
                inactiveTrackColor:
                    AppColors.accentPrimary.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: pos,
                max: total,
                onChanged: (double v) =>
                    onSeek(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
          Text(DurationFormatter.formatRemaining(-remaining),
              style: AppTextStyles.duration),
        ],
      ),
    );
  }
}
