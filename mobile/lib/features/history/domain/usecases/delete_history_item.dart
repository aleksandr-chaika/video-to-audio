import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/history_repository.dart';

class DeleteHistoryItemUseCase implements UseCase<Unit, int> {
  DeleteHistoryItemUseCase(this._repository);

  final HistoryRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(int params) {
    return _repository.delete(params);
  }
}
