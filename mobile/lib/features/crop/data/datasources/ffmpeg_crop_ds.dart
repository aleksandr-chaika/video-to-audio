import 'dart:io';

import '../../../../core/error/exceptions.dart';

/// ⚠ STUB ДЛЯ СИМУЛЯТОРА. См. комментарий в ffmpeg_local_ds.dart.
class FfmpegCropDataSource {
  Future<String> crop({
    required String sourcePath,
    required Duration start,
    required Duration end,
  }) async {
    final src = File(sourcePath);
    if (!src.existsSync()) {
      throw FfmpegException('Source file not found: $sourcePath');
    }
    if (end <= start) {
      throw FfmpegException('Invalid range: end must be after start');
    }
    throw FfmpegException(
      'Crop Audio на iOS-симуляторе не поддерживается. '
      'Запустите приложение на реальном устройстве.',
    );
  }
}
