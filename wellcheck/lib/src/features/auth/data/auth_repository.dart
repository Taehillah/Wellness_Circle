import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/http_exception.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/services/app_database.dart';
import 'models/auth_response.dart';
import 'models/auth_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._database);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AppDatabase _database;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

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
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const HttpRequestException('Authentication failed. Try again.');
      }

      await _ensureFirestoreUser(firebaseUser, normalizedEmail);
      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
      final firestoreData = userDoc.data();

      final existingLocal = await _database.getMemberByEmail(normalizedEmail);
      final user = firestoreData != null
          ? _authUserFromFirestore(
              firebaseUser: firebaseUser,
              data: firestoreData,
              fallbackEmail: normalizedEmail,
            )
          : existingLocal != null
          ? _userFromRecord(existingLocal)
          : _guestUserForEmail(
              normalizedEmail,
              firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
            );

      await _persistLocalProfile(user, firebaseUser.phoneNumber);

      final token = await firebaseUser.getIdToken();
      if (token == null || token.isEmpty) {
        throw const HttpRequestException('Unable to retrieve session token.');
      }
      return AuthResponse(token: token, user: user);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    }
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const HttpRequestException(
          'Unable to create account. Try again.',
        );
      }
      final displayName = name.trim().isEmpty ? 'New User' : name.trim();
      await firebaseUser.updateDisplayName(displayName);

      await _createFirestoreUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? normalizedEmail,
        displayName: displayName,
        userType: userType,
        location: location,
        dateOfBirth: dateOfBirth,
      );

      final now = DateTime.now();
      final user = AuthUser(
        id: _stableIdFromEmail(normalizedEmail),
        name: displayName,
        email: normalizedEmail,
        role: 'user',
        location: location?.trim().isEmpty ?? true ? 'Local' : location!.trim(),
        dateOfBirth: dateOfBirth ?? DateTime(now.year - 40, 1, 1),
        userType: userType,
        createdAt: now,
        updatedAt: now,
      );

      await _persistLocalProfile(user, firebaseUser.phoneNumber);

      final token = await firebaseUser.getIdToken();
      if (token == null || token.isEmpty) {
        throw const HttpRequestException('Unable to retrieve session token.');
      }
      return AuthResponse(token: token, user: user);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (error) {
      throw _mapFirebaseAuthException(error);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<AuthResponse> fetchCurrentUser({String? fallbackToken}) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw const HttpRequestException('No authenticated session found.');
    }
    final email = firebaseUser.email;
    if (email == null) {
      throw const HttpRequestException(
        'Authenticated user has no email address.',
      );
    }
    final normalizedEmail = email.toLowerCase();
    final docSnapshot = await _usersCollection.doc(firebaseUser.uid).get();
    final data = docSnapshot.data();
    final localRecord = await _database.getMemberByEmail(normalizedEmail);

    if (data == null && localRecord == null) {
      throw const HttpRequestException('No profile found for this account.');
    }

    final user = data != null
        ? _authUserFromFirestore(
            firebaseUser: firebaseUser,
            data: data,
            fallbackEmail: normalizedEmail,
          )
        : _userFromRecord(localRecord!);

    if (localRecord == null) {
      await _persistLocalProfile(user, firebaseUser.phoneNumber);
    }

    final token = await firebaseUser.getIdToken();
    if (token == null || token.isEmpty) {
      throw const HttpRequestException('Unable to retrieve session token.');
    }
    return AuthResponse(token: token, user: user);
  }

  Future<void> _ensureFirestoreUser(
    User firebaseUser,
    String fallbackEmail,
  ) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await _createFirestoreUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? fallbackEmail,
        displayName: firebaseUser.displayName,
        userType: 'Pensioner',
      );
    } else {
      await docRef.update({
        'lastSignInAt': FieldValue.serverTimestamp(),
        'lastSignInAtLocal':
            (firebaseUser.metadata.lastSignInTime ?? DateTime.now())
                .toIso8601String(),
      });
    }
  }

  Future<void> _createFirestoreUser({
    required String uid,
    required String email,
    String? displayName,
    String? userType,
    String? location,
    DateTime? dateOfBirth,
  }) async {
    final now = DateTime.now();
    await _usersCollection.doc(uid).set({
      'email': email.toLowerCase(),
      'name': displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : email.split('@').first,
      'role': 'user',
      'legacyId': _stableIdFromEmail(email),
      'userType': userType ?? 'Pensioner',
      'location': location?.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtLocal': now.toIso8601String(),
      'lastSignInAt': FieldValue.serverTimestamp(),
      'lastSignInAtLocal': now.toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> _persistLocalProfile(AuthUser user, String? phone) async {
    await _database.upsertMember(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: phone,
      location: user.location,
      dateOfBirth: user.dateOfBirth,
      userType: user.userType,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      password: '',
    );
  }

  AuthUser _authUserFromFirestore({
    required User firebaseUser,
    required Map<String, dynamic> data,
    required String fallbackEmail,
  }) {
    final email = (data['email'] as String? ?? fallbackEmail).toLowerCase();
    final legacyId = data['legacyId'] as int? ?? _stableIdFromEmail(email);
    final name = (data['name'] as String?)?.trim();
    final location = (data['location'] as String?)?.trim();
    final dobRaw = data['dateOfBirth'] as String?;
    final createdAtRaw =
        data['createdAtLocal'] as String? ?? data['createdAt']?.toString();
    final updatedAtRaw =
        data['lastSignInAtLocal'] as String? ??
        data['lastSignInAt']?.toString();
    return AuthUser(
      id: legacyId,
      name: name?.isNotEmpty == true
          ? name!
          : (firebaseUser.displayName ?? 'Member'),
      email: email,
      role: (data['role'] as String?) ?? 'user',
      location: location,
      dateOfBirth: dobRaw == null || dobRaw.isEmpty
          ? null
          : DateTime.tryParse(dobRaw),
      userType: (data['userType'] as String?) ?? 'Pensioner',
      createdAt: createdAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(createdAtRaw) ?? DateTime.now(),
      updatedAt: updatedAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(updatedAtRaw) ?? DateTime.now(),
    );
  }

  AuthUser _userFromRecord(Map<String, dynamic> record) {
    final email = (record['email'] as String).toLowerCase();
    final location = record['location'] as String?;
    final dobRaw = record['date_of_birth'] as String?;
    final userType = record['user_type'] as String? ?? 'Pensioner';
    final createdAt =
        DateTime.tryParse(record['created_at'] as String? ?? '') ??
        DateTime.now();
    final updatedAt =
        DateTime.tryParse(record['updated_at'] as String? ?? '') ??
        DateTime.now();
    return AuthUser(
      id: record['id'] as int,
      name: record['name'] as String,
      email: email,
      role: 'user',
      location: location,
      dateOfBirth: dobRaw == null || dobRaw.isEmpty
          ? null
          : DateTime.tryParse(dobRaw),
      userType: userType,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  AuthUser _guestUserForEmail(String email, DateTime timestamp) {
    final localPart = email.contains('@') ? email.split('@').first : email;
    final sanitized = localPart
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
        .trim();
    final nameParts = sanitized.isEmpty
        ? <String>[]
        : sanitized.split(RegExp(r'\s+'));
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

  HttpRequestException _mapFirebaseAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
        return const HttpRequestException('Invalid email or password');
      case 'invalid-email':
        return const HttpRequestException('Enter a valid email address');
      case 'user-disabled':
        return const HttpRequestException(
          'This account has been disabled. Contact support.',
        );
      case 'email-already-in-use':
        return const HttpRequestException(
          'An account with this email already exists',
        );
      case 'weak-password':
        return const HttpRequestException(
          'Choose a stronger password (min 6 characters).',
        );
      case 'too-many-requests':
        return const HttpRequestException(
          'Too many attempts. Please wait a moment and try again.',
        );
      default:
        return HttpRequestException(error.message ?? 'Authentication error');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  return AuthRepository(auth, firestore, db);
});
