import 'user_model.dart';

/// Model kết quả phản hồi khi đăng nhập thành công
class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final UserModel? user;

  AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    DateTime? expDate;
    if (json['expiresAt'] != null) {
      expDate = DateTime.tryParse(json['expiresAt'].toString());
    }

    UserModel? parsedUser;
    if (json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    }

    return AuthResponseModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      expiresAt: expDate,
      user: parsedUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
