import 'package:cloud_firestore/cloud_firestore.dart';

class CircleAlertSummary {
  const CircleAlertSummary({
    required this.id,
    required this.senderName,
    required this.createdAt,
    this.message,
    this.locationText,
    this.status,
  });

  final String id;
  final String senderName;
  final DateTime createdAt;
  final String? message;
  final String? locationText;
  final String? status;

  factory CircleAlertSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final created = data['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is String) {
      createdAt = DateTime.tryParse(created) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return CircleAlertSummary(
      id: doc.id,
      senderName: (data['senderName'] as String?)?.trim().isNotEmpty == true
          ? (data['senderName'] as String).trim()
          : 'Member',
      createdAt: createdAt,
      message: (data['message'] as String?)?.trim(),
      locationText: (data['locationText'] as String?)?.trim(),
      status: (data['status'] as String?)?.trim(),
    );
  }
}
