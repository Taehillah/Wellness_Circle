import 'dart:collection';

class AppDatabase {
  AppDatabase._internal() {
    _seedMockMembers();
  }

  static final AppDatabase _instance = AppDatabase._internal();

  factory AppDatabase() => _instance;

  bool _initialized = false;

  final List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _helpRequests = <Map<String, dynamic>>[];

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  void _seedMockMembers() {
    final now = DateTime.now();
    _members
      ..add({
        'id': 1,
        'name': 'Wellness Demo',
        'email': 'demo@mockwellness.app',
        'phone': '+155555501',
        'location': 'Harbor City',
        'date_of_birth': DateTime(now.year - 50, 4, 12).toIso8601String(),
        'user_type': 'Pensioner',
        'password': 'Password123!',
        'created_at': now.subtract(const Duration(days: 60)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'circle_id': 'circle-1',
      })
      ..add({
        'id': 2,
        'name': 'Amina Caregiver',
        'email': 'caregiver@mockwellness.app',
        'phone': '+155555502',
        'location': 'Cedar Town',
        'date_of_birth': DateTime(now.year - 38, 8, 22).toIso8601String(),
        'user_type': 'Lady',
        'password': 'Caregiver123!',
        'created_at': now.subtract(const Duration(days: 45)).toIso8601String(),
        'updated_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'circle_id': 'circle-2',
      });
  }

  Future<void> upsertMember({
    required int id,
    required String name,
    required String email,
    String? phone,
    String? location,
    DateTime? dateOfBirth,
    required String userType,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? password,
    String? circleId,
  }) async {
    await init();
    final normalizedEmail = email.trim().toLowerCase();
    final existingIndex = _members.indexWhere(
      (row) => (row['email'] as String).toLowerCase() == normalizedEmail,
    );

    final data = {
      'id': id,
      'name': name,
      'email': normalizedEmail,
      'phone': phone,
      'location': location,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'user_type': userType,
      'password':
          password ??
          (existingIndex >= 0
              ? _members[existingIndex]['password'] as String? ?? ''
              : ''),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'circle_id':
          circleId ??
          (existingIndex >= 0
              ? _members[existingIndex]['circle_id'] as String?
              : null),
    };

    if (existingIndex >= 0) {
      _members[existingIndex] = data;
    } else {
      _members.add(data);
    }
  }

  Future<Map<String, dynamic>?> getMemberByEmail(String email) async {
    await init();
    final normalizedEmail = email.trim().toLowerCase();
    final match = _members.firstWhere(
      (row) => (row['email'] as String).toLowerCase() == normalizedEmail,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return null;
    return HashMap<String, dynamic>.from(match);
  }

  Future<bool> updateMemberPassword({
    required String email,
    required String newPassword,
  }) async {
    await init();
    final normalizedEmail = email.trim().toLowerCase();
    final index = _members.indexWhere(
      (row) => (row['email'] as String).toLowerCase() == normalizedEmail,
    );
    if (index == -1) return false;
    final updated = HashMap<String, dynamic>.from(_members[index]);
    updated['password'] = newPassword;
    updated['updated_at'] = DateTime.now().toIso8601String();
    _members[index] = updated;
    return true;
  }

  Future<void> insertHelpRequest({
    required String id,
    required int memberId,
    String? message,
    double? lat,
    double? lng,
    String? address,
    DateTime? createdAt,
  }) async {
    await init();
    _helpRequests.add({
      'id': id,
      'member_id': memberId,
      'message': message,
      'lat': lat,
      'lng': lng,
      'address': address,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    });
  }
}
