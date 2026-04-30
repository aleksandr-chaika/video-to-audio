import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/file_utils.dart';

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

    final Directory docs = await getApplicationDocumentsDirectory();
    final String wavDir = p.join(docs.path, 'wav');
    await FileUtils.ensureDir(wavDir);

    final String hint = '${p.basenameWithoutExtension(sourcePath)}_cropped';
    final String target = FileUtils.wavPath(docs.path, hint: hint);

    final List<String> args = <String>[
      '-y',
      '-i', sourcePath,
      '-ss', _toFfmpegTime(start),
      '-to', _toFfmpegTime(end),
      '-acodec', 'pcm_s16le',
      '-ar', '44100',
      '-ac', '2',
      target,
    ];

    final session = await FFmpegKit.executeWithArguments(args);
    final ReturnCode? code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final String? logs = await session.getAllLogsAsString();
      throw FfmpegException('ffmpeg crop failed: ${logs ?? "unknown error"}');
    }
    return target;
  }

  String _toFfmpegTime(Duration d) {
    final int totalMs = d.inMilliseconds;
    final int hours = totalMs ~/ 3600000;
    final int minutes = (totalMs % 3600000) ~/ 60000;
    final int seconds = (totalMs % 60000) ~/ 1000;
    final int ms = totalMs % 1000;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${ms.toString().padLeft(3, '0')}';
  }
}
