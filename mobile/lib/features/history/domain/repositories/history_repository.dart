import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/history_item.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<HistoryItem>>> getAll();
  Future<Either<Failure, HistoryItem>> add(HistoryItem item);
  Future<Either<Failure, Unit>> delete(int id);
}
