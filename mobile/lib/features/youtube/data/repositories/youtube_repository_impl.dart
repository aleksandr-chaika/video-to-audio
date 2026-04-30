import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/yt_job.dart';
import '../../domain/repositories/youtube_repository.dart';
import '../datasources/youtube_remote_ds.dart';

class YoutubeRepositoryImpl implements YoutubeRepository {
  YoutubeRepositoryImpl(this._ds);

  final YoutubeRemoteDataSource _ds;

  @override
  Future<Either<Failure, YtJob>> createJob(String url) async {
    try {
      final YtJob job = await _ds.createJob(url);
      return Right<Failure, YtJob>(job);
    } on ApiException catch (e) {
      return Left<Failure, YtJob>(_mapApiException(e));
    } on DioException catch (e) {
      return Left<Failure, YtJob>(_mapDio(e));
    } on Object catch (e) {
      return Left<Failure, YtJob>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, YtJob>> getStatus(String jobId) async {
    try {
      final YtJob job = await _ds.getStatus(jobId);
      return Right<Failure, YtJob>(job);
    } on ApiException catch (e) {
      return Left<Failure, YtJob>(_mapApiException(e));
    } on DioException catch (e) {
      return Left<Failure, YtJob>(_mapDio(e));
    } on Object catch (e) {
      return Left<Failure, YtJob>(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, YtJob>> pollStatus(
    String jobId, {
    Duration interval = const Duration(milliseconds: 1500),
    Duration timeout = const Duration(minutes: 5),
  }) async* {
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final Either<Failure, YtJob> result = await getStatus(jobId);
      yield result;
      final bool stop = result.fold(
        (_) => true,
        (YtJob job) => job.status.isTerminal,
      );
      if (stop) return;
      await Future<void>.delayed(interval);
    }
    yield const Left<Failure, YtJob>(
      ServerFailure('Превышено время ожидания', code: 'TIMEOUT'),
    );
  }

  @override
  Future<Either<Failure, String>> downloadFile(
    String jobId, {
    required String targetDir,
  }) async {
    try {
      final String target = '$targetDir/${jobId}_yt.wav';
      final String path = await _ds.downloadFile(jobId, target);
      return Right<Failure, String>(path);
    } on ApiException catch (e) {
      return Left<Failure, String>(_mapApiException(e));
    } on DioException catch (e) {
      return Left<Failure, String>(_mapDio(e));
    } on Object catch (e) {
      return Left<Failure, String>(UnknownFailure(e.toString()));
    }
  }

  Failure _mapApiException(ApiException e) {
    switch (e.code) {
      case 'BOT_DETECTED':
        return const BotDetectedFailure();
      case 'GEO_BLOCKED':
        return const GeoBlockedFailure();
      case 'YT_UNAVAILABLE':
      case 'EXTRACTION_FAILED':
        return UnavailableFailure(e.message);
      case 'INVALID_URL':
      case 'VALIDATION_ERROR':
        return ValidationFailure(e.message);
      default:
        return ServerFailure(e.message, code: e.code, statusCode: e.statusCode);
    }
  }

  Failure _mapDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkFailure();
    }
    return ServerFailure(
      e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }
}
