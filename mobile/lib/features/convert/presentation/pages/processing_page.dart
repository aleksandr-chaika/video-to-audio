import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/thumbnail_helper.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../history/domain/entities/history_item.dart';
import '../../../history/presentation/bloc/history_bloc.dart';
import '../bloc/convert_bloc.dart';

/// Image#2 — Process Loading. Полноэкранный модал поверх затемнения.
class ProcessingPage extends StatefulWidget {
  const ProcessingPage({required this.sourcePath, super.key});
  final String sourcePath;

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage> {
  @override
  void initState() {
    super.initState();
    context.read<ConvertBloc>().add(ConvertStarted(widget.sourcePath));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConvertBloc, ConvertState>(
      listener: (BuildContext context, ConvertState state) {
        switch (state) {
          case ConvertDone():
            _handleDone(context, state);
          case ConvertFailure(:final String message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.danger,
              ),
            );
            context.go('/');
          case ConvertIdle() || ConvertProcessing():
            break;
        }
      },
      child: const Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: LoadingOverlay()),
      ),
    );
  }

  /// Обработка успешной конвертации: извлекаем превью-кадр из исходного
  /// видео (для MP4/MOV), сохраняем в History, переходим к Result.
  Future<void> _handleDone(BuildContext context, ConvertDone state) async {
    final SourceFormat src = SourceFormatX.fromString(
        FileUtils.extensionOf(state.sourcePath));
    final String title = FileUtils.basenameWithoutExt(state.sourcePath);

    // Извлекаем preview только для видео-форматов (MP4/MOV).
    String? thumbnailPath;
    if (FileUtils.isVideo(state.sourcePath)) {
      thumbnailPath =
          await ThumbnailHelper.extractFromVideo(state.sourcePath);
    }
    if (!context.mounted) return;

    context.read<HistoryBloc>().add(
          HistoryItemAdded(
            HistoryItem(
              id: null,
              sourceType: SourceType.local,
              sourceFormat: src,
              outputFormat: SourceFormat.wav,
              filePath: state.wavPath,
              durationMs: state.durationMs,
              createdAt: DateTime.now(),
              title: title,
              thumbnailPath: thumbnailPath,
            ),
          ),
        );
    context.go('/result', extra: <String, Object?>{
      'path': state.wavPath,
      'durationMs': state.durationMs,
      'sourceFormat': src.name,
      'title': title,
      'thumbnailPath': thumbnailPath,
    });
  }
}
