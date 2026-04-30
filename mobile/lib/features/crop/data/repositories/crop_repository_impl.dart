import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/crop_repository.dart';
import '../datasources/ffmpeg_crop_ds.dart';

class CropRepositoryImpl implements CropRepository {
  CropRepositoryImpl(this._ds);
  final FfmpegCropDataSource _ds;

  @override
  Future<Either<Failure, String>> crop({
    required String sourcePath,
    required Duration start,
    required Duration end,
  }) async {
    try {
      final String path =
          await _ds.crop(sourcePath: sourcePath, start: start, end: end);
      return Right<Failure, String>(path);
    } on FfmpegException catch (e) {
      return Left<Failure, String>(ConversionFailure(e.message));
    } on Object catch (e) {
      return Left<Failure, String>(UnknownFailure(e.toString()));
    }
  }
}
