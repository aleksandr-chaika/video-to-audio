import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/history_item.dart';

/// SQLite-доступ к истории конвертаций. Создаёт схему лениво.
///
/// Хранит `file_path` / `thumbnail_path` как **относительные** пути от
/// каталога Documents. Это критично для iOS: симулятор присваивает новый
/// sandbox container UUID при каждой переустановке приложения — абсолютные
/// пути становятся невалидными, файлы "теряются".
class HistoryLocalDataSource {
  HistoryLocalDataSource._(this._db);

  final Database _db;

  static const String tableName = 'history';
  static const String _createSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      source_type   TEXT NOT NULL,
      source_format TEXT NOT NULL,
      output_format TEXT NOT NULL,
      file_path     TEXT NOT NULL,
      title         TEXT,
      duration_ms   INTEGER NOT NULL,
      thumbnail_path TEXT,
      created_at    INTEGER NOT NULL
    )
  ''';
  static const String _indexSql =
      'CREATE INDEX IF NOT EXISTS idx_history_created_at ON $tableName(created_at DESC)';

  static Future<HistoryLocalDataSource> create(String dbPath) async {
    final Database db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(_createSql);
        await db.execute(_indexSql);
      },
    );
    return HistoryLocalDataSource._(db);
  }

  Future<String> _docsRoot() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// Превращает абсолютный путь в относительный от Documents.
  /// Если путь не лежит внутри Documents — пытаемся отрезать всё до и
  /// включая "/Documents/" (рестор после смены sandbox UUID). Иначе
  /// возвращаем basename — лучше потерять подкаталог, чем хранить
  /// невалидный absolute.
  String _toStored(String absolute, String docsRoot) {
    if (absolute.startsWith('$docsRoot/')) {
      return absolute.substring(docsRoot.length + 1);
    }
    final int idx = absolute.indexOf('/Documents/');
    if (idx >= 0) {
      return absolute.substring(idx + '/Documents/'.length);
    }
    final int slash = absolute.lastIndexOf('/');
    return slash >= 0 ? absolute.substring(slash + 1) : absolute;
  }

  /// Превращает stored-путь обратно в абсолютный. Если в БД лежит legacy
  /// абсолютный путь — отдаём его (логика _fromRow всё равно пройдёт через
  /// File.existsSync и при отсутствии файла HistoryItem отрисуется пустым).
  String _toAbsolute(String stored, String docsRoot) {
    if (stored.startsWith('/')) return stored;
    return '$docsRoot/$stored';
  }

  Future<List<HistoryItem>> getAll() async {
    final List<Map<String, Object?>> rows = await _db.query(
      tableName,
      orderBy: 'created_at DESC',
    );
    final String docsRoot = await _docsRoot();
    return rows.map((Map<String, Object?> r) => _fromRow(r, docsRoot)).toList(
          growable: false,
        );
  }

  Future<HistoryItem> insert(HistoryItem item) async {
    final String docsRoot = await _docsRoot();
    final int id = await _db.insert(tableName, _toRow(item, docsRoot));
    return item.copyWith(id: id);
  }

  Future<void> delete(int id) async {
    await _db.delete(tableName, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Map<String, Object?> _toRow(HistoryItem item, String docsRoot) {
    return <String, Object?>{
      'source_type': item.sourceType.name,
      'source_format': item.sourceFormat.name,
      'output_format': item.outputFormat.name,
      'file_path': _toStored(item.filePath, docsRoot),
      'title': item.title,
      'duration_ms': item.durationMs,
      'thumbnail_path': item.thumbnailPath != null
          ? _toStored(item.thumbnailPath!, docsRoot)
          : null,
      'created_at': item.createdAt.millisecondsSinceEpoch,
    };
  }

  HistoryItem _fromRow(Map<String, Object?> row, String docsRoot) {
    try {
      final String storedPath = row['file_path'] as String;
      final String? storedThumb = row['thumbnail_path'] as String?;
      return HistoryItem(
        id: row['id'] as int?,
        sourceType: row['source_type'] == 'youtube'
            ? SourceType.youtube
            : SourceType.local,
        sourceFormat: SourceFormatX.fromString(row['source_format'] as String?),
        outputFormat: SourceFormatX.fromString(row['output_format'] as String?),
        filePath: _toAbsolute(storedPath, docsRoot),
        title: row['title'] as String?,
        durationMs: (row['duration_ms'] as int?) ?? 0,
        thumbnailPath:
            storedThumb != null ? _toAbsolute(storedThumb, docsRoot) : null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at'] as int?) ?? 0,
        ),
      );
    } on Object catch (e) {
      throw StorageException('Не удалось прочитать запись: $e');
    }
  }
}
