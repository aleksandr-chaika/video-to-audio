import 'dart:io';

import '../../../../core/error/exceptions.dart';

/// Запускает ffmpeg/ffprobe локально (на устройстве).
///
/// ⚠ STUB ДЛЯ СИМУЛЯТОРА. На реальном устройстве вернуть импорты
/// ffmpeg_kit_flutter_new и оригинальную реализацию (см. историю git).
/// Причина: ни один публичный пакет ffmpeg-kit-flutter не ship'ит
/// simulator-slice (.framework только под device-arm64), линкер падает.
class FfmpegLocalDataSource {
  Future<({String path, int durationMs})> convertToWav(
    String sourcePath,
  ) async {
    final src = File(sourcePath);
    if (!src.existsSync()) {
      throw FfmpegException('Source file not found: $sourcePath');
    }
    throw FfmpegException(
      'Локальная конвертация на iOS-симуляторе не поддерживается '
      '(ffmpeg-kit без simulator slice). '
      'Запустите на реальном iPhone/iPad — там всё работает. '
      'YouTube-извлечение через сервер работает и на симуляторе.',
    );
  }
}
