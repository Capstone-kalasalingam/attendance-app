class UserModel {
  final String id;
  final String username;
  final String? email;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'admin',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'is_active': isActive,
    };
  }
}
