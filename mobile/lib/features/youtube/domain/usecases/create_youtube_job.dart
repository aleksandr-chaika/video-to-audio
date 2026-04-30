import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/yt_job.dart';
import '../repositories/youtube_repository.dart';

class CreateYoutubeJobUseCase implements UseCase<YtJob, String> {
  CreateYoutubeJobUseCase(this._repository);
  final YoutubeRepository _repository;

  @override
  Future<Either<Failure, YtJob>> call(String params) =>
      _repository.createJob(params);
}
