import 'dart:convert';

class CircleInvitePayload {
  const CircleInvitePayload({required this.circleId, required this.ownerEmail});

  final String circleId;
  final String ownerEmail;

  static const _prefix = 'wellcheck_circle_v1';

  Map<String, dynamic> toJson() => {
    'circleId': circleId,
    'ownerEmail': ownerEmail,
    'issuedAt': DateTime.now().toIso8601String(),
  };

  String encode() {
    final payload = jsonEncode(toJson());
    final bytes = utf8.encode('$_prefix|$payload');
    return base64UrlEncode(bytes);
  }

  static CircleInvitePayload? decode(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = utf8.decode(base64Url.decode(raw.trim()));
      if (!decoded.startsWith('$_prefix|')) return null;
      final jsonString = decoded.substring('$_prefix|'.length);
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      final circleId = map['circleId'] as String?;
      final ownerEmail = map['ownerEmail'] as String?;
      if (circleId == null || ownerEmail == null) return null;
      return CircleInvitePayload(circleId: circleId, ownerEmail: ownerEmail);
    } catch (_) {
      return null;
    }
  }
}
