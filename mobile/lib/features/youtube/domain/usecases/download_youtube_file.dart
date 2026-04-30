import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/youtube_repository.dart';

class DownloadYoutubeFileParams {
  const DownloadYoutubeFileParams({
    required this.jobId,
    required this.targetDir,
  });
  final String jobId;
  final String targetDir;
}

class DownloadYoutubeFileUseCase
    implements UseCase<String, DownloadYoutubeFileParams> {
  DownloadYoutubeFileUseCase(this._repository);
  final YoutubeRepository _repository;

  @override
  Future<Either<Failure, String>> call(DownloadYoutubeFileParams params) =>
      _repository.downloadFile(params.jobId, targetDir: params.targetDir);
}
