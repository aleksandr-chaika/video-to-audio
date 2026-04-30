import 'package:sqflite/sqflite.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/history_item.dart';

/// SQLite-доступ к истории конвертаций. Создаёт схему лениво.
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

  Future<List<HistoryItem>> getAll() async {
    final List<Map<String, Object?>> rows = await _db.query(
      tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<HistoryItem> insert(HistoryItem item) async {
    final int id = await _db.insert(tableName, _toRow(item));
    return item.copyWith(id: id);
  }

  Future<void> delete(int id) async {
    await _db.delete(tableName, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Map<String, Object?> _toRow(HistoryItem item) => <String, Object?>{
        'source_type': item.sourceType.name,
        'source_format': item.sourceFormat.name,
        'output_format': item.outputFormat.name,
        'file_path': item.filePath,
        'title': item.title,
        'duration_ms': item.durationMs,
        'thumbnail_path': item.thumbnailPath,
        'created_at': item.createdAt.millisecondsSinceEpoch,
      };

  HistoryItem _fromRow(Map<String, Object?> row) {
    try {
      return HistoryItem(
        id: row['id'] as int?,
        sourceType: row['source_type'] == 'youtube'
            ? SourceType.youtube
            : SourceType.local,
        sourceFormat: SourceFormatX.fromString(row['source_format'] as String?),
        outputFormat: SourceFormatX.fromString(row['output_format'] as String?),
        filePath: row['file_path'] as String,
        title: row['title'] as String?,
        durationMs: (row['duration_ms'] as int?) ?? 0,
        thumbnailPath: row['thumbnail_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (row['created_at'] as int?) ?? 0,
        ),
      );
    } on Object catch (e) {
      throw StorageException('Не удалось прочитать запись: $e');
    }
  }
}
