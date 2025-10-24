import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/dio_client.dart';
import '../../../shared/network/http_exception.dart';
import 'models/auth_response.dart';
import 'models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // Offline-first login: accept any credentials and create a local session.
    final now = DateTime.now();
    final namePart = email.trim().split('@').first;
    final displayName = (namePart.isEmpty ? 'User' : namePart)
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
        .join(' ');
    final user = AuthUser(
      id: now.millisecondsSinceEpoch % 1000000,
      name: displayName,
      email: email.trim(),
      role: 'user',
      location: 'Local',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    final token = 'offline-${now.millisecondsSinceEpoch}';
    return AuthResponse(token: token, user: user);
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

    // Offline-first register: accept any details and create a local session.
    final now = DateTime.now();
    final user = AuthUser(
      id: now.millisecondsSinceEpoch % 1000000,
      name: name.trim().isEmpty ? 'New User' : name.trim(),
      email: email.trim(),
      role: 'user',
      location: location?.trim().isEmpty ?? true ? 'Local' : location!.trim(),
      createdAt: now,
      updatedAt: now,
    );
    final token = 'offline-${now.millisecondsSinceEpoch}';
    return AuthResponse(token: token, user: user);
  }

  Future<void> logout() async {
    // Offline-first logout: no remote call needed.
    return;
  }

  Future<AuthResponse> fetchCurrentUser({String? fallbackToken}) async {
    // Offline-first: indicate connectivity so the controller retains the saved session.
    throw const HttpRequestException(
      'Offline mode: using saved session',
      isConnectivity: true,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
