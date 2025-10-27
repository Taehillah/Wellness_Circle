import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/models/auth_session.dart';
import '../../../shared/services/app_database.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/network/http_exception.dart';

class CircleMembershipRepository {
  CircleMembershipRepository(this._firestore, this._auth, this._database);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppDatabase _database;

  CollectionReference<Map<String, dynamic>> get _circlesCollection =>
      _firestore.collection('circles');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<void> ensureCircleExists({
    required String circleId,
    AuthSession? owner,
  }) async {
    final normalizedCircleId = circleId.trim();
    if (normalizedCircleId.isEmpty) {
      throw const HttpRequestException('Circle id cannot be empty.');
    }
    final docRef = _circlesCollection.doc(normalizedCircleId);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      return;
    }
    final now = DateTime.now();
    final Map<String, dynamic> data = {
      'circleId': normalizedCircleId,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtLocal': now.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtLocal': now.toIso8601String(),
    };
    if (owner != null) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        data['ownerUid'] = uid;
      }
      data['ownerMemberId'] = owner.user.id;
      data['ownerName'] = owner.user.name;
      data['ownerEmail'] = owner.user.email;
    }
    await docRef.set(data, SetOptions(merge: true));
  }

  Future<void> joinCircle({
    required AuthSession session,
    required String circleId,
    String role = 'caregiver',
    String status = 'checkedIn',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const HttpRequestException('No authenticated user available.');
    }

    final normalizedCircleId = circleId.trim();
    if (normalizedCircleId.isEmpty) {
      throw const HttpRequestException('Circle id cannot be empty.');
    }

    await ensureCircleExists(circleId: normalizedCircleId);

    final now = DateTime.now();

    // Update the user profile with the shared circle id.
    await _usersCollection.doc(uid).set({
      'circleId': normalizedCircleId,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedAtLocal': now.toIso8601String(),
    }, SetOptions(merge: true));

    // Mirror to local database.
    await _database.upsertMember(
      id: session.user.id,
      name: session.user.name,
      email: session.user.email,
      phone: session.user.phone,
      location: session.user.location,
      dateOfBirth: session.user.dateOfBirth,
      userType: session.user.userType,
      createdAt: session.user.createdAt,
      updatedAt: now,
      circleId: normalizedCircleId,
    );

    // Create/update the circle member record.
    await _circlesCollection
        .doc(normalizedCircleId)
        .collection('members')
        .doc(session.user.id.toString())
        .set({
          'displayName': session.user.name,
          'role': role,
          'status': status,
          'email': session.user.email,
          'phone': session.user.phone ?? _auth.currentUser?.phoneNumber,
          'userType': session.user.userType,
          'lastJoinedAt': FieldValue.serverTimestamp(),
          'lastJoinedAtLocal': now.toIso8601String(),
        }, SetOptions(merge: true));
  }

  Future<String?> findCircleIdByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final snapshot = await _usersCollection
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    final circleId = data['circleId'] as String?;
    final legacyId = data['legacyId']?.toString();
    if (circleId != null && circleId.trim().isNotEmpty) {
      return circleId.trim();
    }
    if (legacyId != null && legacyId.isNotEmpty) {
      return 'circle-$legacyId';
    }
    return null;
  }

  Future<String?> findCircleIdByPhone(String phone) async {
    final normalized = phone.trim();
    if (normalized.isEmpty) return null;
    final snapshot = await _usersCollection
        .where('phone', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    final circleId = data['circleId'] as String?;
    final legacyId = data['legacyId']?.toString();
    if (circleId != null && circleId.trim().isNotEmpty) {
      return circleId.trim();
    }
    if (legacyId != null && legacyId.isNotEmpty) {
      return 'circle-$legacyId';
    }
    return null;
  }
}

final circleMembershipRepositoryProvider = Provider<CircleMembershipRepository>(
  (ref) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final database = ref.watch(appDatabaseProvider);
    return CircleMembershipRepository(firestore, auth, database);
  },
);
