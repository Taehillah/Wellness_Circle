import 'dart:async';

import 'package:riverpod/riverpod.dart';

import '../../../shared/network/http_exception.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/services/preferences_service.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_response.dart';
import '../data/models/auth_session.dart';
import '../data/models/auth_user.dart';

const _sessionStorageKey = 'wellcheck.auth.session';

class AuthState {
  const AuthState({
    required this.session,
    required this.status,
    this.errorMessage,
  });

  final AuthSession? session;
  final AuthStatus status;
  final String? errorMessage;

  bool get isAuthenticated => session != null;
  bool get isAdmin => session?.isAdmin ?? false;

  AuthState copyWith({
    AuthSession? session,
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      session: session ?? this.session,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState(
        session: null,
        status: AuthStatus.idle,
      );
}

enum AuthStatus {
  idle,
  restoring,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthController extends Notifier<AuthState> {
  late final PreferencesService _preferences;
  late final AuthRepository _repository;
  Completer<void>? _restoreCompleter;
  Timer? _debounce;
  AuthSession? _pendingSession; // holds restored session until biometric unlock

  @override
  AuthState build() {
    _preferences = ref.read(preferencesServiceProvider);
    _repository = ref.read(authRepositoryProvider);
    scheduleMicrotask(restoreSession);
    return AuthState.initial();
  }

  Future<void> restoreSession() async {
    if (_restoreCompleter != null) {
      return _restoreCompleter!.future;
    }

    final completer = Completer<void>();
    _restoreCompleter = completer;
    state = state.copyWith(status: AuthStatus.restoring, errorMessage: null);
    try {
      final saved = _preferences.getJson(_sessionStorageKey);
      if (saved == null) {
        _setUnauthenticated();
        completer.complete();
        return;
      }
      // Defer restored session until user authenticates (e.g., biometrics).
      final session = AuthSession.fromJson(saved);
      _pendingSession = session;
      // Keep user at login until they unlock.
      _setUnauthenticated();
      completer.complete();
    } on HttpRequestException catch (error) {
      if (error.isConnectivity) {
        // Defer restored session until unlock, even when offline.
        final saved = _preferences.getJson(_sessionStorageKey);
        if (saved != null) {
          _pendingSession = AuthSession.fromJson(saved);
          _setUnauthenticated();
          completer.complete();
        } else {
          _setUnauthenticated();
          completer.complete();
        }
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          session: null,
          errorMessage: error.message,
        );
        await _preferences.remove(_sessionStorageKey);
        completer.completeError(error);
      }
    } catch (error) {
      state = state.copyWith(
        status: AuthStatus.error,
        session: null,
        errorMessage: error.toString(),
      );
      await _preferences.remove(_sessionStorageKey);
      completer.completeError(error);
    } finally {
      _restoreCompleter = null;
    }
  }

  Future<bool> unlockWithBiometrics() async {
    try {
      // Prefer the pending session captured during restore; fall back to persisted.
      var session = _pendingSession;
      if (session == null) {
        final saved = _preferences.getJson(_sessionStorageKey);
        if (saved == null) {
          return false;
        }
        session = AuthSession.fromJson(saved);
      }
      _pendingSession = null;
      _setSession(session);
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final AuthResponse response =
          await _repository.login(email: email, password: password);
      final session = AuthSession(token: response.token, user: response.user);
      // Persist to local database for control centre records.
      final db = ref.read(appDatabaseProvider);
      await db.upsertMember(
        id: session.user.id,
        name: session.user.name,
        email: session.user.email,
        phone: null,
        location: session.user.location,
        dateOfBirth: session.user.dateOfBirth,
        userType: session.user.userType,
        createdAt: session.user.createdAt,
        updatedAt: session.user.updatedAt,
      );
      await _persistSession(session);
      _setSession(session);
      state = state.copyWith(status: AuthStatus.authenticated);
    } on HttpRequestException catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    String? location,
    DateTime? dateOfBirth,
    required String userType,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final AuthResponse response = await _repository.register(
        name: name,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        location: location,
        dateOfBirth: dateOfBirth,
        userType: userType,
      );
      final session = AuthSession(token: response.token, user: response.user);
      // Persist to local database for control centre records.
      final db = ref.read(appDatabaseProvider);
      await db.upsertMember(
        id: session.user.id,
        name: session.user.name,
        email: session.user.email,
        phone: null,
        location: session.user.location,
        dateOfBirth: session.user.dateOfBirth,
        userType: session.user.userType,
        createdAt: session.user.createdAt,
        updatedAt: session.user.updatedAt,
      );
      await _persistSession(session);
      _setSession(session);
      state = state.copyWith(status: AuthStatus.authenticated);
    } on HttpRequestException catch (error) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: error.message);
      rethrow;
    }
  }

  Future<void> logout({bool remote = true}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      // Token cleared with persisted session removal.
      await _preferences.remove(_sessionStorageKey);
      if (remote) {
        await _repository.logout();
      }
    } catch (_) {
      // Swallow logout errors, but ensure local session is removed.
    } finally {
      _setUnauthenticated();
    }
  }

  void handleUnauthorized() {
    // Debounce repeated 401 events from parallel requests.
    if (_debounce?.isActive ?? false) {
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () {
      logout(remote: false);
    });
  }

  void updateUser(AuthUser user) {
    final current = state.session;
    if (current == null) {
      return;
    }
    final updated = AuthSession(token: current.token, user: user);
    _setSession(updated);
    _persistSession(updated);
  }

  void _setSession(AuthSession session) {
    state = state.copyWith(
      session: session,
      status: AuthStatus.authenticated,
      errorMessage: null,
    );
  }

  void _setUnauthenticated() {
    state = state.copyWith(
      session: null,
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  Future<void> _persistSession(AuthSession session) async {
    await _preferences.setJson(_sessionStorageKey, session.toJson());
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authControllerProvider).status;
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authControllerProvider).session?.user;
});

final authSessionProvider = Provider<AuthSession?>((ref) {
  return ref.watch(authControllerProvider).session;
});
