import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/file_utils.dart';

/// Crop audio через нативный AVFoundation (iOS) — MethodChannel.
class FfmpegCropDataSource {
  static const MethodChannel _channel =
      MethodChannel('mp3craft/audio_converter');

  Future<String> crop({
    required String sourcePath,
    required Duration start,
    required Duration end,
  }) async {
    if (!File(sourcePath).existsSync()) {
      throw FfmpegException('Source file not found: $sourcePath');
    }
    if (end <= start) {
      throw FfmpegException('Invalid range: end must be after start');
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    final String wavDir = p.join(docs.path, 'wav');
    await FileUtils.ensureDir(wavDir);
    final String hint = '${p.basenameWithoutExtension(sourcePath)}_cropped';
    final String target = FileUtils.wavPath(docs.path, hint: hint);

    try {
      final dynamic raw = await _channel.invokeMethod<dynamic>(
        'crop',
        <String, Object?>{
          'sourcePath': sourcePath,
          'targetPath': target,
          'startMs': start.inMilliseconds,
          'endMs': end.inMilliseconds,
        },
      );
      if (raw is! Map) {
        throw FfmpegException('Native crop returned unexpected payload');
      }
      final Map<Object?, Object?> response = raw as Map<Object?, Object?>;
      final String resultPath = response['path'] as String? ?? target;
      if (!File(resultPath).existsSync()) {
        throw FfmpegException('Crop produced empty output');
      }
      return resultPath;
    } on PlatformException catch (e) {
      throw FfmpegException(e.message ?? 'Native crop failed (${e.code})');
    }
  }
}
