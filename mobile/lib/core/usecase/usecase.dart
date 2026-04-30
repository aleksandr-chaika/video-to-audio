import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Generic-каркас use case для clean architecture.
abstract class UseCase<T, P> {
  Future<Either<Failure, T>> call(P params);
}

/// Маркер «нет параметров».
class NoParams {
  const NoParams();
}
