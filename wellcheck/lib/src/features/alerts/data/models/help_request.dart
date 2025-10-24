import '../../../auth/data/models/auth_user.dart';
import 'help_location.dart';

class HelpRequest {
  const HelpRequest({
    required this.id,
    required this.user,
    this.message,
    this.location,
    required this.actions,
    required this.notifications,
    required this.createdAt,
  });

  final int id;
  final AuthUser? user;
  final String? message;
  final HelpLocation? location;
  final List<dynamic> actions;
  final List<dynamic> notifications;
  final DateTime createdAt;

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      id: json['id'] as int,
      user: json['user'] == null
          ? null
          : AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String?,
      location: json['location'] == null
          ? null
          : HelpLocation.fromJson(json['location'] as Map<String, dynamic>),
      actions: (json['actions'] as List<dynamic>? ?? <dynamic>[]).toList(),
      notifications: (json['notifications'] as List<dynamic>? ?? <dynamic>[]).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
