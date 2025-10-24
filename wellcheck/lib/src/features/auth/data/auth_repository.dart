import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/dio_client.dart';
import '../../../shared/network/http_exception.dart';
import 'models/auth_response.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data ?? {};
      return AuthResponse.fromJson(data);
    } on DioException catch (error) {
      throw HttpRequestException.fromDio(error);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? location,
  }) async {
    if (password != confirmPassword) {
      throw const HttpRequestException('Passwords do not match');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'location': location,
        },
      );
      final data = response.data ?? {};
      return AuthResponse.fromJson(data);
    } on DioException catch (error) {
      throw HttpRequestException.fromDio(error);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } on DioException catch (error) {
      throw HttpRequestException.fromDio(error);
    }
  }

  Future<AuthResponse> fetchCurrentUser({String? fallbackToken}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/auth/me');
      final data = response.data ?? {};
      if (data.containsKey('token')) {
        return AuthResponse.fromJson(data);
      }
      final token = data['token'] as String? ?? fallbackToken ?? '';
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return AuthResponse.fromJson({
        'token': token,
        'user': userJson,
      });
    } on DioException catch (error) {
      throw HttpRequestException.fromDio(error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
