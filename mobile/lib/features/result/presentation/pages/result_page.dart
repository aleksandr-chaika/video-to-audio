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

/// Image#3 — Result.
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
    final Duration? d = await _player.setFilePath(widget.payload.filePath);
    if (!mounted) return;
    setState(() {
      _duration = d ??
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
        _player
          ..seek(Duration.zero)
          ..pause();
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

  void _toggle() {
    _player.playing ? _player.pause() : _player.play();
  }

  Future<void> _share() async {
    await Share.shareXFiles(<XFile>[XFile(widget.payload.filePath)]);
  }

  void _delete() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text('Delete?', style: AppTextStyles.appBarTitle),
        content: Text(
          'Запись будет удалена из истории и с устройства.',
          style: AppTextStyles.subtitle,
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final HistoryState st = context.read<HistoryBloc>().state;
              if (st is HistoryLoaded) {
                final HistoryItem? item = st.items
                    .where(
                        (HistoryItem h) => h.filePath == widget.payload.filePath)
                    .firstOrNull;
                if (item?.id != null) {
                  context
                      .read<HistoryBloc>()
                      .add(HistoryItemDeleted(item!.id!));
                }
              }
              context.go('/');
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ResultPayload p = widget.payload;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: <Widget>[
          // Ambient blue ellipse top
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
            child: Column(
              children: <Widget>[
                _ResultAppBar(onClose: () => context.go('/'), onDelete: _delete),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimens.space16),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: AppDimens.space14),
                        AudioPreviewBlock(
                          imagePath: p.thumbnailPath,
                          placeholderIcon: p.sourceFormat == SourceFormat.mp4
                              ? Icons.videocam_rounded
                              : Icons.music_note_rounded,
                          height: AppDimens.previewIconOnlyHeight,
                          bottomOverlay: _PreviewBottomRow(
                            sourceLabel: p.sourceFormat.label,
                            duration: _duration,
                          ),
                        ),
                        const SizedBox(height: AppDimens.space20),
                        _CropAudioButton(onTap: () {
                          context.push('/crop', extra: <String, Object?>{
                            'path': p.filePath,
                            'durationMs': _duration.inMilliseconds,
                          });
                        }),
                        const SizedBox(height: AppDimens.space14),
                        _PlayerBar(
                          playing: _player.playing,
                          position: _position,
                          duration: _duration,
                          onToggle: _toggle,
                          onSeek: _player.seek,
                        ),
                      ],
                    ),
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
                    label: 'Share',
                    icon: Icons.ios_share_rounded,
                    onPressed: _share,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultAppBar extends StatelessWidget {
  const _ResultAppBar({required this.onClose, required this.onDelete});
  final VoidCallback onClose;
  final VoidCallback onDelete;

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
            IconButtonCircle(
              icon: Icons.delete_outline_rounded,
              iconAsset: 'assets/images/icons/ic_delete.png',
              onPressed: onDelete,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBottomRow extends StatelessWidget {
  const _PreviewBottomRow({required this.sourceLabel, required this.duration});
  final String sourceLabel;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FormatBadge(sourceLabel),
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

class _CropAudioButton extends StatelessWidget {
  const _CropAudioButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radius20),
        onTap: onTap,
        child: Ink(
          height: AppDimens.primaryButtonHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accentSolid.withValues(alpha: 0.4),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radius20),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.crop_rounded,
                    color: AppColors.accentSolid, size: 18),
                const SizedBox(width: AppDimens.space8),
                Text(
                  'Crop Audio',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.accentSolid),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerBar extends StatefulWidget {
  const _PlayerBar({
    required this.playing,
    required this.position,
    required this.duration,
    required this.onToggle,
    required this.onSeek,
  });

  final bool playing;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;
  final ValueChanged<Duration> onSeek;

  @override
  State<_PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<_PlayerBar> {
  /// Локальное значение во время drag; стримовые обновления игнорируются,
  /// пока пользователь держит палец на ползунке. После отпускания — один seek.
  double? _dragValue;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final double total =
        widget.duration.inMilliseconds.clamp(1, 1 << 31).toDouble();
    final double streamPos =
        widget.position.inMilliseconds.clamp(0, total).toDouble();
    final double pos = _dragging ? (_dragValue ?? streamPos) : streamPos;
    final Duration displayed = Duration(milliseconds: pos.round());
    final Duration remaining = widget.duration - displayed;
    return _buildBody(context, total: total, pos: pos, position: displayed, remaining: remaining);
  }

  Widget _buildBody(
    BuildContext context, {
    required double total,
    required double pos,
    required Duration position,
    required Duration remaining,
  }) {
    // Figma layout (Image #18 / #20):
    //  • Внешний контейнер: тёмная плашка #14191F, radius 20, тонкий бордер.
    //  • Слева крупная круглая pause 56×56 (accentSolid@20% bg, accent icon).
    //  • Справа column: slider сверху, timestamps под ним (00:45 / -2:38).
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppDimens.radius20),
        border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.accentSolid.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.playing
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: AppColors.accentSolid,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: AppColors.accentSolid,
                    inactiveTrackColor: const Color(0x33FFFFFF),
                    thumbColor: Colors.white,
                    overlayShape: SliderComponentShape.noOverlay,
                    trackShape: const RoundedRectSliderTrackShape(),
                  ),
                  child: Slider(
                    value: pos.clamp(0, total),
                    max: total,
                    onChangeStart: (double v) {
                      setState(() {
                        _dragging = true;
                        _dragValue = v;
                      });
                    },
                    onChanged: (double v) {
                      setState(() => _dragValue = v);
                    },
                    onChangeEnd: (double v) {
                      widget.onSeek(Duration(milliseconds: v.round()));
                      setState(() {
                        _dragging = false;
                        _dragValue = null;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(DurationFormatter.format(position),
                          style: AppTextStyles.duration),
                      Text(DurationFormatter.formatRemaining(-remaining),
                          style: AppTextStyles.duration),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
