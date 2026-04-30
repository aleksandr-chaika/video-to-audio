import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/history_item.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_ds.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._dataSource);

  final HistoryLocalDataSource _dataSource;

  @override
  Future<Either<Failure, List<HistoryItem>>> getAll() async {
    try {
      final items = await _dataSource.getAll();
      return Right<Failure, List<HistoryItem>>(items);
    } on StorageException catch (e) {
      return Left<Failure, List<HistoryItem>>(StorageFailure(e.message));
    } on Object catch (e) {
      return Left<Failure, List<HistoryItem>>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HistoryItem>> add(HistoryItem item) async {
    try {
      final saved = await _dataSource.insert(item);
      return Right<Failure, HistoryItem>(saved);
    } on Object catch (e) {
      return Left<Failure, HistoryItem>(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(int id) async {
    try {
      final List<HistoryItem> all = await _dataSource.getAll();
      final HistoryItem? item = all.where((HistoryItem h) => h.id == id).firstOrNull;
      await _dataSource.delete(id);
      if (item != null) {
        await _safeRemoveFile(item.filePath);
        if (item.thumbnailPath != null) {
          await _safeRemoveFile(item.thumbnailPath!);
        }
      }
      return const Right<Failure, Unit>(unit);
    } on Object catch (e) {
      return Left<Failure, Unit>(StorageFailure(e.toString()));
    }
  }

  Future<void> _safeRemoveFile(String path) async {
    try {
      final f = File(path);
      if (f.existsSync()) await f.delete();
    } on Object {
      // best effort cleanup; logging happens in caller if needed
    }
  }
}
