import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/file_utils.dart';

/// Запускает ffmpeg/ffprobe локально (на устройстве).
class FfmpegLocalDataSource {
  /// Конвертирует [sourcePath] в WAV (PCM 16-bit, 44.1 kHz, stereo).
  /// Возвращает (path к wav, длительность в мс).
  Future<({String path, int durationMs})> convertToWav(
      String sourcePath) async {
    final src = File(sourcePath);
    if (!src.existsSync()) {
      throw FfmpegException('Source file not found: $sourcePath');
    }

    final Directory docs = await getApplicationDocumentsDirectory();
    final String wavDir = p.join(docs.path, 'wav');
    await FileUtils.ensureDir(wavDir);

    final String hint = p.basenameWithoutExtension(sourcePath);
    final String target = FileUtils.wavPath(docs.path, hint: hint);

    final List<String> args = <String>[
      '-y',
      '-i', sourcePath,
      '-vn',
      '-acodec', 'pcm_s16le',
      '-ar', '44100',
      '-ac', '2',
      target,
    ];

    final session = await FFmpegKit.executeWithArguments(args);
    final ReturnCode? code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final String? logs = await session.getAllLogsAsString();
      throw FfmpegException('ffmpeg failed: ${logs ?? "unknown error"}');
    }
    if (!File(target).existsSync()) {
      throw FfmpegException('ffmpeg produced empty output');
    }

    final int durationMs = await _probeDurationMs(target);
    return (path: target, durationMs: durationMs);
  }

  Future<int> _probeDurationMs(String path) async {
    try {
      final session = await FFprobeKit.getMediaInformation(path);
      final info = session.getMediaInformation();
      final String? raw = info?.getDuration();
      if (raw == null) return 0;
      final double seconds = double.tryParse(raw) ?? 0;
      return (seconds * 1000).round();
    } on Object {
      return 0;
    }
  }
}
