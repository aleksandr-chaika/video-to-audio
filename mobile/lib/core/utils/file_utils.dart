import 'dart:io';

import 'package:path/path.dart' as p;

/// Утилиты для определения типа файла и работы с путями.
class FileUtils {
  FileUtils._();

  /// Возвращает 'mp3' / 'mp4' / 'wav' / расширение в нижнем регистре.
  static String extensionOf(String path) =>
      p.extension(path).replaceFirst('.', '').toLowerCase();

  static bool isMp3(String path) => extensionOf(path) == 'mp3';
  static bool isMp4(String path) => extensionOf(path) == 'mp4';
  static bool isWav(String path) => extensionOf(path) == 'wav';
  static bool isVideo(String path) {
    final String ext = extensionOf(path);
    return ext == 'mp4' || ext == 'mov' || ext == 'm4v' || ext == 'webm';
  }

  static String basenameWithoutExt(String path) =>
      p.basenameWithoutExtension(path);

  static Future<int> sizeOf(String path) async {
    final file = File(path);
    if (!file.existsSync()) return 0;
    return file.length();
  }

  /// Путь для генерируемого WAV в каталоге documents.
  static String wavPath(String docsDir, {String? hint}) {
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String name = hint == null ? stamp : '${hint}_$stamp';
    return p.join(docsDir, 'wav', '$name.wav');
  }

  static Future<void> ensureDir(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }
}
