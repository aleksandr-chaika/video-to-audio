import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/crop_repository.dart';

class CropAudioParams {
  const CropAudioParams({
    required this.sourcePath,
    required this.start,
    required this.end,
  });
  final String sourcePath;
  final Duration start;
  final Duration end;
}

class CropAudioUseCase implements UseCase<String, CropAudioParams> {
  CropAudioUseCase(this._repository);
  final CropRepository _repository;

  @override
  Future<Either<Failure, String>> call(CropAudioParams params) {
    return _repository.crop(
      sourcePath: params.sourcePath,
      start: params.start,
      end: params.end,
    );
  }
}
