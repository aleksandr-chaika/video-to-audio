import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Утилиты для получения preview-картинки:
/// — для локальных видео (MP4/MOV) — извлечь первый кадр через video_thumbnail
/// — для YouTube — скачать thumbnail_url через dio
///
/// Возвращают абсолютный path к JPEG в Application Documents
/// (для долговременного хранения вместе с History-записью).
class ThumbnailHelper {
  ThumbnailHelper._();

  /// Извлекает кадр на 1-й секунде видео и сохраняет JPEG.
  /// Возвращает path или null при ошибке.
  static Future<String?> extractFromVideo(String videoPath) async {
    try {
      final Directory dir = await _thumbnailsDir();
      final String name = '${DateTime.now().millisecondsSinceEpoch}_'
          '${p.basenameWithoutExtension(videoPath)}.jpg';
      final String outPath = p.join(dir.path, name);
      final String? result = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: outPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: 1000, // 1-я секунда
        quality: 75,
        maxWidth: 720,
      );
      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('extractFromVideo failed: $e\n$st');
      }
      return null;
    }
  }

  /// Скачивает thumbnail по URL (i.ytimg.com/...) и сохраняет JPEG.
  /// Возвращает path или null при ошибке.
  static Future<String?> downloadFromUrl(String url, {Dio? dio}) async {
    try {
      final Directory dir = await _thumbnailsDir();
      final String name = '${DateTime.now().millisecondsSinceEpoch}_'
          '${url.hashCode.abs()}.jpg';
      final String outPath = p.join(dir.path, name);
      final Dio client = dio ?? Dio();
      await client.download(
        url,
        outPath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );
      final File file = File(outPath);
      if (!file.existsSync() || file.lengthSync() == 0) return null;
      return outPath;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('downloadFromUrl failed: $e\n$st');
      }
      return null;
    }
  }

  static Future<Directory> _thumbnailsDir() async {
    final Directory docs = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(docs.path, 'thumbnails'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
