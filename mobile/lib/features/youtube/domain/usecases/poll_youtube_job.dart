import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/yt_job.dart';
import '../repositories/youtube_repository.dart';

class PollYoutubeJobUseCase {
  PollYoutubeJobUseCase(this._repository);
  final YoutubeRepository _repository;

  Stream<Either<Failure, YtJob>> call(String jobId) =>
      _repository.pollStatus(jobId);
}
