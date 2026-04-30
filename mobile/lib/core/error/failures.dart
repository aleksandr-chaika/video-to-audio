import 'package:equatable/equatable.dart';

/// Базовый sealed-класс ошибок domain-уровня.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message, runtimeType];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет соединения']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.code, this.statusCode});

  final String? code;
  final int? statusCode;

  @override
  List<Object?> get props => <Object?>[...super.props, code, statusCode];
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CancelledFailure extends Failure {
  const CancelledFailure() : super('Операция отменена');
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class ConversionFailure extends Failure {
  const ConversionFailure(super.message);
}

class BotDetectedFailure extends Failure {
  const BotDetectedFailure()
      : super(
          'YouTube запрашивает подтверждение «не бот». Попробуйте позже.',
        );
}

class UnavailableFailure extends Failure {
  const UnavailableFailure(super.message);
}

class GeoBlockedFailure extends Failure {
  const GeoBlockedFailure() : super('Видео недоступно в данном регионе');
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Что-то пошло не так']);
}
