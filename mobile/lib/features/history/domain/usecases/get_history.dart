import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/history_item.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase implements UseCase<List<HistoryItem>, NoParams> {
  GetHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, List<HistoryItem>>> call(NoParams params) {
    return _repository.getAll();
  }
}
