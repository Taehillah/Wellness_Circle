import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/dio_client.dart';
import '../../../shared/network/http_exception.dart';
import 'models/auth_response.dart';
import 'models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  int _stableIdFromEmail(String email) {
    final e = email.trim().toLowerCase();
    int hash = 0;
    for (final codeUnit in e.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff; // simple stable hash
    }
    // constrain to a friendly positive range
    return (hash % 1000000) + 1;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // Offline-first login: accept any credentials and create a local session.
    final now = DateTime.now();
    final defaultDob = DateTime(now.year - 45, 1, 1);
    final namePart = email.trim().split('@').first;
    final displayName = (namePart.isEmpty ? 'User' : namePart)
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1)))
        .join(' ');
    final user = AuthUser(
      id: _stableIdFromEmail(email),
      name: displayName,
      email: email.trim(),
      role: 'user',
      location: 'Local',
      dateOfBirth: defaultDob,
      userType: 'Pensioner',
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
    final token = 'offline-${email.trim().toLowerCase()}';
    return AuthResponse(token: token, user: user);
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? location,
    DateTime? dateOfBirth,
    required String userType,
  }) async {
    if (password != confirmPassword) {
      throw const HttpRequestException('Passwords do not match');
    }

    // Offline-first register: accept any details and create a local session.
    final now = DateTime.now();
    final defaultDob = DateTime(now.year - 40, 1, 1);
    final user = AuthUser(
      id: _stableIdFromEmail(email),
      name: name.trim().isEmpty ? 'New User' : name.trim(),
      email: email.trim(),
      role: 'user',
      location: location?.trim().isEmpty ?? true ? 'Local' : location!.trim(),
      dateOfBirth: dateOfBirth ?? defaultDob,
      userType: userType,
      createdAt: now,
      updatedAt: now,
    );
    final token = 'offline-${email.trim().toLowerCase()}';
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
