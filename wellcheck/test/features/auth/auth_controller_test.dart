import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellcheck/src/features/auth/application/auth_controller.dart';
import 'package:wellcheck/src/features/auth/data/auth_repository.dart';
import 'package:wellcheck/src/features/auth/data/models/auth_response.dart';
import 'package:wellcheck/src/features/auth/data/models/auth_session.dart';
import 'package:wellcheck/src/features/auth/data/models/auth_user.dart';
import 'package:wellcheck/src/shared/providers/shared_providers.dart';
import 'package:wellcheck/src/shared/services/preferences_service.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SharedPreferences prefs;

  setUp(() async {
    repository = _MockAuthRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('restoreSession hydrates state from persisted storage', () async {
    final savedUser = AuthUser(
      id: 1,
      name: 'Margaret Hamilton',
      email: 'margaret@example.com',
      role: 'user',
      location: 'Springfield, IL',
      dateOfBirth: DateTime.utc(1936, 8, 17),
      userType: 'Pensioner',
      createdAt: DateTime.utc(2024, 1, 1),
      updatedAt: DateTime.utc(2024, 1, 2),
    );
    final savedSession = AuthSession(token: 'persisted-token', user: savedUser);
    await prefs.setString(
      'wellcheck.auth.session',
      jsonEncode(savedSession.toJson()),
    );

    final refreshedUser = savedUser.copyWith(name: 'Margaret H.');
    when(
      () => repository.fetchCurrentUser(fallbackToken: any(named: 'fallbackToken')),
    ).thenAnswer(
      (_) async => AuthResponse(token: 'persisted-token', user: refreshedUser),
    );

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      preferencesServiceProvider.overrideWithValue(PreferencesService(prefs)),
      authRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).restoreSession();

    final state = container.read(authControllerProvider);
    expect(state.isAuthenticated, isTrue);
    expect(state.session?.user.name, 'Margaret H.');
    expect(state.status, AuthStatus.authenticated);
  });
}
