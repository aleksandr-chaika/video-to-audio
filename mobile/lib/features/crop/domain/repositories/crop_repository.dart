import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

abstract class CropRepository {
  /// Обрезает [sourcePath] от [start] до [end]; возвращает путь к новому WAV.
  Future<Either<Failure, String>> crop({
    required String sourcePath,
    required Duration start,
    required Duration end,
  });
}
