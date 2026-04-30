import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/yt_job.dart';

class YoutubeRemoteDataSource {
  YoutubeRemoteDataSource(this._dio, this._endpoints);

  final Dio _dio;
  final ApiEndpoints _endpoints;

  Future<YtJob> createJob(String url) async {
    final Response<dynamic> resp = await _dio.post<dynamic>(
      _endpoints.youtubeJobs,
      data: <String, dynamic>{'url': url, 'format': 'wav'},
    );
    if (resp.statusCode != 202) {
      throw _toException(resp);
    }
    final Map<String, dynamic> body = resp.data as Map<String, dynamic>;
    return YtJob(
      jobId: body['job_id'] as String,
      status: YtJobStatus.parse(body['status'] as String?),
    );
  }

  Future<YtJob> getStatus(String jobId) async {
    final Response<dynamic> resp =
        await _dio.get<dynamic>(_endpoints.youtubeJobStatus(jobId));
    if (resp.statusCode != 200) {
      throw _toException(resp);
    }
    final Map<String, dynamic> body = resp.data as Map<String, dynamic>;
    return _jobFromJson(body);
  }

  /// Скачивает файл WAV в [targetPath]; возвращает путь.
  Future<String> downloadFile(String jobId, String targetPath) async {
    final Response<List<int>> resp = await _dio.get<List<int>>(
      _endpoints.youtubeJobFile(jobId),
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (int? s) => s != null && s >= 200 && s < 500,
      ),
    );
    if (resp.statusCode != 200) {
      throw _toException(resp);
    }
    final List<int> bytes = resp.data ?? <int>[];
    if (bytes.isEmpty) {
      throw ApiException('Сервер вернул пустой файл',
          statusCode: resp.statusCode);
    }
    final f = File(targetPath);
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  YtJob _jobFromJson(Map<String, dynamic> body) {
    return YtJob(
      jobId: body['job_id'] as String,
      status: YtJobStatus.parse(body['status'] as String?),
      progress: (body['progress'] as int?) ?? 0,
      title: body['title'] as String?,
      thumbnailUrl: body['thumbnail_url'] as String?,
      durationSec: body['duration_sec'] as int?,
      errorCode: body['error_code'] as String?,
      errorMessage: body['error_message'] as String?,
    );
  }

  ApiException _toException(Response<dynamic> resp) {
    final dynamic body = resp.data;
    String message = 'HTTP ${resp.statusCode}';
    String? code;
    if (body is Map<String, dynamic>) {
      message = (body['detail'] as String?) ?? message;
      code = body['code'] as String?;
    }
    return ApiException(message, code: code, statusCode: resp.statusCode);
  }
}
