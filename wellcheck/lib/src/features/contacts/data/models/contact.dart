import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final DateTime createdAt;

  factory Contact.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final phone = json['phone'] as String?;
    final createdRaw = json['createdAt'];
    DateTime createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return Contact(
      id: id ?? '',
      name: name ?? 'Contact',
      phone: phone ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
