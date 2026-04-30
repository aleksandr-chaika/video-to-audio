import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/yt_job.dart';

abstract class YoutubeRepository {
  Future<Either<Failure, YtJob>> createJob(String url);
  Future<Either<Failure, YtJob>> getStatus(String jobId);
  Stream<Either<Failure, YtJob>> pollStatus(
    String jobId, {
    Duration interval = const Duration(milliseconds: 1500),
    Duration timeout = const Duration(minutes: 5),
  });
  Future<Either<Failure, String>> downloadFile(
    String jobId, {
    required String targetDir,
  });
}
