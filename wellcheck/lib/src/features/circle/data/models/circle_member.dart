import 'package:cloud_firestore/cloud_firestore.dart';

enum CircleMemberRole { survivor, caregiver, contactOnly }

enum CircleMemberStatus { needsAttention, checkedIn, awaitingSetup }

class CircleMember {
  const CircleMember({
    required this.id,
    required this.displayName,
    required this.role,
    required this.status,
    this.relationship,
    this.phone,
    this.photoUrl,
    this.isPreferred = false,
    this.isManual = false,
    this.lastCheckInAt,
    this.lastAlertAt,
  });

  final String id;
  final String displayName;
  final CircleMemberRole role;
  final CircleMemberStatus status;
  final String? relationship;
  final String? phone;
  final String? photoUrl;
  final bool isPreferred;
  final bool isManual;
  final DateTime? lastCheckInAt;
  final DateTime? lastAlertAt;

  CircleMember copyWith({
    String? id,
    String? displayName,
    CircleMemberRole? role,
    CircleMemberStatus? status,
    String? relationship,
    String? phone,
    String? photoUrl,
    bool? isPreferred,
    bool? isManual,
    DateTime? lastCheckInAt,
    DateTime? lastAlertAt,
  }) {
    return CircleMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      isPreferred: isPreferred ?? this.isPreferred,
      isManual: isManual ?? this.isManual,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      lastAlertAt: lastAlertAt ?? this.lastAlertAt,
    );
  }

  factory CircleMember.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CircleMember(
      id: doc.id,
      displayName: (data['displayName'] as String?)?.trim().isNotEmpty == true
          ? (data['displayName'] as String).trim()
          : 'Member',
      role: _roleFromString(data['role'] as String?),
      status: _statusFromString(data['status'] as String?),
      relationship: (data['relationship'] as String?)?.trim(),
      phone: (data['phone'] as String?)?.trim(),
      photoUrl: (data['photoUrl'] as String?)?.trim(),
      isPreferred: data['isPreferred'] as bool? ?? false,
      isManual: data['isManual'] as bool? ?? false,
      lastCheckInAt: _parseDate(data['lastCheckInAt']),
      lastAlertAt: _parseDate(data['lastAlertAt']),
    );
  }

  static CircleMemberRole _roleFromString(String? value) {
    switch (value) {
      case 'survivor':
        return CircleMemberRole.survivor;
      case 'caregiver':
        return CircleMemberRole.caregiver;
      case 'contactOnly':
        return CircleMemberRole.contactOnly;
      default:
        return CircleMemberRole.caregiver;
    }
  }

  static CircleMemberStatus _statusFromString(String? value) {
    switch (value) {
      case 'needsAttention':
        return CircleMemberStatus.needsAttention;
      case 'awaitingSetup':
        return CircleMemberStatus.awaitingSetup;
      case 'checkedIn':
      default:
        return CircleMemberStatus.checkedIn;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
