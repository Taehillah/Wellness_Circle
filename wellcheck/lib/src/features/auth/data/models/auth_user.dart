class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.location,
    this.dateOfBirth,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String role; // 'admin' | 'user'
  final String? location;
  final DateTime? dateOfBirth;
  final String userType;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role.toLowerCase() == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final dobString = json['dateOfBirth'] as String? ?? json['date_of_birth'] as String?;
    return AuthUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      location: json['location'] as String?,
      dateOfBirth: dobString == null || dobString.isEmpty ? null : DateTime.tryParse(dobString),
      userType: json['userType'] as String? ??
          json['user_type'] as String? ??
          'Pensioner',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'location': location,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'userType': userType,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  AuthUser copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    String? location,
    DateTime? dateOfBirth,
    String? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
