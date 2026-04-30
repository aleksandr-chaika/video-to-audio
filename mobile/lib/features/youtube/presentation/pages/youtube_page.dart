import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../history/domain/entities/history_item.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../bloc/youtube_bloc.dart';

class YoutubePage extends StatefulWidget {
  const YoutubePage({required this.url, super.key});
  final String url;

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final dir = await getApplicationDocumentsDirectory();
    if (!mounted) return;
    context.read<YoutubeBloc>().add(
          YoutubeExtractRequested(url: widget.url, targetDir: dir.path),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<YoutubeBloc, YoutubeState>(
      listener: (BuildContext context, YoutubeState state) {
        switch (state) {
          case YoutubeDone(:final String filePath, :final job):
            context.read<HistoryBloc>().add(
                  HistoryItemAdded(
                    HistoryItem(
                      id: null,
                      sourceType: SourceType.youtube,
                      sourceFormat: SourceFormat.mp4,
                      outputFormat: SourceFormat.wav,
                      filePath: filePath,
                      title: job.title,
                      durationMs: (job.durationSec ?? 0) * 1000,
                      thumbnailPath: null,
                      createdAt: DateTime.now(),
                    ),
                  ),
                );
            context.go('/result', extra: <String, Object?>{
              'path': filePath,
              'durationMs': (job.durationSec ?? 0) * 1000,
              'sourceFormat': 'mp4',
              'title': job.title,
            });
          case YoutubeFailure(:final String message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.danger,
              ),
            );
            context.go('/');
          case YoutubeIdle() ||
                YoutubeCreating() ||
                YoutubePolling() ||
                YoutubeDownloading():
            break;
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LoadingOverlay(
            title: 'Extracting from YouTube...',
            subtitle:
                'Это займёт от нескольких секунд до пары минут.\nНе закрывайте экран.',
          ),
        ),
      ),
    );
  }
}
