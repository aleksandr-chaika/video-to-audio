/// Низкоуровневые исключения data-слоя. Маппятся в Failure в репозиториях.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode/$code): $message';
}

class FfmpegException implements Exception {
  FfmpegException(this.message);

  final String message;

  @override
  String toString() => 'FfmpegException: $message';
}

class StorageException implements Exception {
  StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}
