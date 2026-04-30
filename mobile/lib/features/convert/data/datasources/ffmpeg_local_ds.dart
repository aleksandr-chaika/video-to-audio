import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/file_utils.dart';

/// Локальная конвертация в WAV через нативный AVFoundation (iOS).
///
/// Используется MethodChannel `mp3craft/audio_converter`, реализованный в
/// Swift (`ios/Runner/AudioConverter.swift` + `AppDelegate.swift`).
/// Это работает и на симуляторе, и на устройстве — без ffmpeg-зависимостей.
///
/// Имя класса осталось `FfmpegLocalDataSource` для обратной совместимости с DI.
class FfmpegLocalDataSource {
  static const MethodChannel _channel =
      MethodChannel('mp3craft/audio_converter');

  Future<({String path, int durationMs})> convertToWav(String sourcePath) async {
    if (!File(sourcePath).existsSync()) {
      throw FfmpegException('Source file not found: $sourcePath');
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    final String wavDir = p.join(docs.path, 'wav');
    await FileUtils.ensureDir(wavDir);

    final String hint = p.basenameWithoutExtension(sourcePath);
    final String target = FileUtils.wavPath(docs.path, hint: hint);

    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        'convertToWav',
        <String, Object?>{'sourcePath': sourcePath, 'targetPath': target},
      );
      if (raw is! Map) {
        throw FfmpegException('Native converter returned unexpected payload');
      }
      final Map<Object?, Object?> response = raw as Map<Object?, Object?>;
      final String resultPath = response['path'] as String? ?? target;
      final int durationMs = (response['durationMs'] as int?) ?? 0;
      if (!File(resultPath).existsSync()) {
        throw FfmpegException('Converter produced empty output');
      }
      return (path: resultPath, durationMs: durationMs);
    } on PlatformException catch (e) {
      throw FfmpegException(e.message ?? 'Native conversion failed (${e.code})');
    }
  }
}
