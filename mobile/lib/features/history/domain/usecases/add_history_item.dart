import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

class AddHistoryItemUseCase implements UseCase<HistoryItem, HistoryItem> {
  AddHistoryItemUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, HistoryItem>> call(HistoryItem params) {
    return _repository.add(params);
  }
}
