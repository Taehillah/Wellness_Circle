import 'package:dio/dio.dart';

class HttpRequestException implements Exception {
  const HttpRequestException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final dynamic details;

  @override
  String toString() => 'HttpRequestException(statusCode: $statusCode, message: $message)';

  static HttpRequestException fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;
    String message = error.message ?? 'Unexpected error';

    if (data is Map<String, dynamic>) {
      final errorMessage = data['message'] ?? data['error'];
      if (errorMessage is String) {
        message = errorMessage;
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    return HttpRequestException(
      message,
      statusCode: statusCode,
      details: data,
    );
  }
}
