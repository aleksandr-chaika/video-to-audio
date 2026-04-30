import 'dart:developer' as developer;

import 'package:dio/dio.dart';

Dio createDio(String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      validateStatus: (int? status) =>
          status != null && status >= 200 && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        developer.log(
          '→ ${options.method} ${options.uri}',
          name: 'http',
        );
        handler.next(options);
      },
      onResponse: (Response<dynamic> response, ResponseInterceptorHandler handler) {
        developer.log(
          '← ${response.statusCode} ${response.requestOptions.uri}',
          name: 'http',
        );
        handler.next(response);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        developer.log(
          'ERROR ${error.type} ${error.requestOptions.uri}: ${error.message}',
          name: 'http',
          error: error,
        );
        handler.next(error);
      },
    ),
  );

  return dio;
}
