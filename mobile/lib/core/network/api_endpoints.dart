import 'dart:io' show Platform;

class ApiEndpoints {
  ApiEndpoints({required this.baseUrl});

  final String baseUrl;

  static String get defaultBaseUrl {
    // Симулятор iOS видит localhost напрямую; Android-эмулятор — через 10.0.2.2.
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static const String apiPrefix = '/api/v1';

  String get health => '$baseUrl$apiPrefix/health';
  String get youtubeJobs => '$baseUrl$apiPrefix/youtube/jobs';
  String youtubeJobStatus(String jobId) =>
      '$baseUrl$apiPrefix/youtube/jobs/$jobId';
  String youtubeJobFile(String jobId) =>
      '$baseUrl$apiPrefix/youtube/jobs/$jobId/file';
}
