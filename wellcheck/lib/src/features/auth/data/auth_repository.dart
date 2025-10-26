import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/dio_client.dart';
import '../../../shared/network/http_exception.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/services/app_database.dart';
import 'models/auth_response.dart';
import 'models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._dio, this._database);

  final Dio _dio;
  final AppDatabase _database;

  int _stableIdFromEmail(String email) {
    final e = email.trim().toLowerCase();
    int hash = 0;
    for (final codeUnit in e.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return (hash % 1000000) + 1;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final now = DateTime.now();
    final record = await _database.getMemberByEmail(normalizedEmail);

    if (record != null) {
      final storedPassword = (record['password'] as String?) ?? '';
      final user = _userFromRecord(record).copyWith(updatedAt: now);

      await _database.upsertMember(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: record['phone'] as String?,
        location: user.location,
        dateOfBirth: user.dateOfBirth,
        userType: user.userType,
        createdAt: user.createdAt,
        updatedAt: now,
        password: storedPassword,
      );

      final token = 'offline-$normalizedEmail';
      return AuthResponse(token: token, user: user);
    }

    final newUser = _guestUserForEmail(normalizedEmail, now);

    await _database.upsertMember(
      id: newUser.id,
      name: newUser.name,
      email: newUser.email,
      phone: null,
      location: newUser.location,
      dateOfBirth: newUser.dateOfBirth,
      userType: newUser.userType,
      createdAt: newUser.createdAt,
      updatedAt: newUser.updatedAt,
      password: password.trim(),
    );

    final token = 'offline-$normalizedEmail';
    return AuthResponse(token: token, user: newUser);
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

    final normalizedEmail = email.trim().toLowerCase();
    final existing = await _database.getMemberByEmail(normalizedEmail);
    if (existing != null) {
      throw const HttpRequestException('An account with this email already exists');
    }

    final now = DateTime.now();
    final defaultDob = DateTime(now.year - 40, 1, 1);
    final user = AuthUser(
      id: _stableIdFromEmail(normalizedEmail),
      name: name.trim().isEmpty ? 'New User' : name.trim(),
      email: normalizedEmail,
      role: 'user',
      location: location?.trim().isEmpty ?? true ? 'Local' : location!.trim(),
      dateOfBirth: dateOfBirth ?? defaultDob,
      userType: userType,
      createdAt: now,
      updatedAt: now,
    );

    await _database.upsertMember(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: null,
      location: user.location,
      dateOfBirth: user.dateOfBirth,
      userType: user.userType,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      password: password.trim(),
    );

    final token = 'offline-$normalizedEmail';
    return AuthResponse(token: token, user: user);
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    if (newPassword.trim().length < 8) {
      throw const HttpRequestException('Password must be at least 8 characters long');
    }
    final normalizedEmail = email.trim().toLowerCase();
    final exists = await _database.updateMemberPassword(
      email: normalizedEmail,
      newPassword: newPassword.trim(),
    );
    if (!exists) {
      throw const HttpRequestException('Account not found for the provided email');
    }
  }

  Future<void> logout() async {
    return;
  }

  Future<AuthResponse> fetchCurrentUser({String? fallbackToken}) async {
    throw const HttpRequestException(
      'Offline mode: using saved session',
      isConnectivity: true,
    );
  }

  AuthUser _userFromRecord(Map<String, dynamic> record) {
    final email = (record['email'] as String).toLowerCase();
    final location = record['location'] as String?;
    final dobRaw = record['date_of_birth'] as String?;
    final userType = record['user_type'] as String? ?? 'Pensioner';
    final createdAt = DateTime.tryParse(record['created_at'] as String? ?? '') ?? DateTime.now();
    final updatedAt = DateTime.tryParse(record['updated_at'] as String? ?? '') ?? DateTime.now();
    return AuthUser(
      id: record['id'] as int,
      name: record['name'] as String,
      email: email,
      role: 'user',
      location: location,
      dateOfBirth: dobRaw == null || dobRaw.isEmpty ? null : DateTime.tryParse(dobRaw),
      userType: userType,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AuthUser _guestUserForEmail(String email, DateTime timestamp) {
    final localPart = email.contains('@') ? email.split('@').first : email;
    final sanitized = localPart.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ').trim();
    final nameParts =
        sanitized.isEmpty ? <String>[] : sanitized.split(RegExp(r'\s+'));
    final friendlyName = nameParts.isEmpty
        ? 'Guest User'
        : nameParts
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
            )
            .join(' ')
            .trim();
    final defaultDob = DateTime(timestamp.year - 40, 1, 1);

    return AuthUser(
      id: _stableIdFromEmail(email),
      name: friendlyName.isEmpty ? 'Guest User' : friendlyName,
      email: email,
      role: 'user',
      location: 'Local',
      dateOfBirth: defaultDob,
      userType: 'Pensioner',
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final db = ref.watch(appDatabaseProvider);
  return AuthRepository(dio, db);
});
