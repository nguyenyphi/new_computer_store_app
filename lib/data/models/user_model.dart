/// Model người dùng hệ thống Computer Store
class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String? phoneNumber;
  final bool isActive;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] != null ? (json['userId'] as num).toInt() : (json['id'] != null ? (json['id'] as num).toInt() : 0),
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'Customer',
      phoneNumber: json['phoneNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
    };
  }
}
