import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/dio_client.dart';
import '../../../shared/network/http_exception.dart';
import 'models/help_request.dart';
import 'models/need_help_payload.dart';

class AlertsRepository {
  AlertsRepository(this._dio);

  final Dio _dio;

  Future<HelpRequest?> sendNeedHelp(NeedHelpPayload payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/alerts/need-help',
        data: payload.toJson(),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return null;
      }
      final requestData = raw['request'];
      if (requestData is Map<String, dynamic>) {
        return HelpRequest.fromJson(requestData);
      }
      if (raw.containsKey('id')) {
        return HelpRequest.fromJson(raw);
      }
      return null;
    } on DioException catch (error) {
      throw HttpRequestException.fromDio(error);
    }
  }

  Future<List<HelpRequest>> fetchRecentRequests() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/alerts/recent');
      final data = response.data ?? {};
      final requests = data['requests'] as List<dynamic>? ?? <dynamic>[];
      return requests
          .map((item) => HelpRequest.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw HttpRequestException.fromDio(error);
    }
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AlertsRepository(dio);
});
