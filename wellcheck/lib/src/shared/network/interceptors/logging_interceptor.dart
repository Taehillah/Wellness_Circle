import 'dart:developer';

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('[DIO][REQUEST] ${options.method} ${options.uri}', name: 'Dio');
    if (options.data != null) {
      log('Payload: ${options.data}', name: 'Dio');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('[DIO][RESPONSE] ${response.statusCode} ${response.requestOptions.uri}', name: 'Dio');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('[DIO][ERROR] ${err.response?.statusCode} ${err.message}', name: 'Dio', error: err, stackTrace: err.stackTrace);
    super.onError(err, handler);
  }
}
