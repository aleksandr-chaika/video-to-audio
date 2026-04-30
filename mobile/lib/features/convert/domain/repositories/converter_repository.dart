import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

class ConvertedAudio {
  const ConvertedAudio({
    required this.path,
    required this.durationMs,
    this.title,
  });

  final String path;
  final int durationMs;
  final String? title;
}

abstract class ConverterRepository {
  Future<Either<Failure, ConvertedAudio>> convertToWav({
    required String sourcePath,
  });
}
