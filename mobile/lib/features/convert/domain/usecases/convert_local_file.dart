import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/converter_repository.dart';

class ConvertLocalFileUseCase implements UseCase<ConvertedAudio, String> {
  ConvertLocalFileUseCase(this._repository);

  final ConverterRepository _repository;

  @override
  Future<Either<Failure, ConvertedAudio>> call(String params) {
    return _repository.convertToWav(sourcePath: params);
  }
}
