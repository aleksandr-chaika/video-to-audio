import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/converter_repository.dart';
import '../datasources/ffmpeg_local_ds.dart';

class ConverterRepositoryImpl implements ConverterRepository {
  ConverterRepositoryImpl(this._ds);

  final FfmpegLocalDataSource _ds;

  @override
  Future<Either<Failure, ConvertedAudio>> convertToWav({
    required String sourcePath,
  }) async {
    try {
      final result = await _ds.convertToWav(sourcePath);
      return Right<Failure, ConvertedAudio>(
        ConvertedAudio(path: result.path, durationMs: result.durationMs),
      );
    } on FfmpegException catch (e) {
      return Left<Failure, ConvertedAudio>(ConversionFailure(e.message));
    } on Object catch (e) {
      return Left<Failure, ConvertedAudio>(UnknownFailure(e.toString()));
    }
  }
}
