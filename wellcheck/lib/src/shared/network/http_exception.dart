import 'package:dio/dio.dart';

class HttpRequestException implements Exception {
  const HttpRequestException(this.message, {this.statusCode, this.details, this.isConnectivity = false});

  final String message;
  final int? statusCode;
  final dynamic details;
  final bool isConnectivity;

  @override
  String toString() => 'HttpRequestException(statusCode: $statusCode, message: $message)';

  static HttpRequestException fromDio(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;
    String message = error.message ?? 'Unexpected error';

    // Provide a friendlier message for connectivity issues.
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        // On Flutter web, cross-origin/CORS issues often surface as "XMLHttpRequest error."
        (error.type == DioExceptionType.unknown &&
            (error.message?.toLowerCase().contains('xmlhttprequest error') ?? false))) {
      return const HttpRequestException(
        'Cannot connect to the server. Ensure the backend is running and API_BASE_URL is correct.',
        isConnectivity: true,
      );
    }

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
