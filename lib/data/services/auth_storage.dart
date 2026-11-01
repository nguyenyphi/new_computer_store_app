import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dịch vụ lưu trữ bảo mật (Access Token, thời gian hết hạn, thông tin user)
/// sử dụng Keystore (Android) qua flutter_secure_storage.
class AuthStorage {
  static const String _keyAccessToken = 'access_token';
  static const String _keyExpiresAt = 'expires_at';
  static const String _keyUserData = 'user_data';

  final FlutterSecureStorage _storage;

  AuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            );

  /// Lưu Token và ngày hết hạn
  Future<void> saveAuthData({
    required String accessToken,
    DateTime? expiresAt,
    Map<String, dynamic>? userData,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);

    if (expiresAt != null) {
      await _storage.write(
        key: _keyExpiresAt,
        value: expiresAt.toUtc().toIso8601String(),
      );
    }

    if (userData != null) {
      await _storage.write(
        key: _keyUserData,
        value: jsonEncode(userData),
      );
    }
  }

  /// Lấy Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Lấy thời điểm hết hạn của Token
  Future<DateTime?> getExpiresAt() async {
    final value = await _storage.read(key: _keyExpiresAt);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Kiểm tra Token có còn hợp lệ và chưa hết hạn không
  Future<bool> hasValidToken() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return false;

    final expiresAt = await getExpiresAt();
    if (expiresAt != null) {
      // Trừ hao 30 giây để tránh gửi token sát lúc hết hạn
      final isExpired = DateTime.now().toUtc().isAfter(
            expiresAt.subtract(const Duration(seconds: 30)),
          );
      if (isExpired) return false;
    }

    return true;
  }

  /// Lấy thông tin user đã cache
  Future<Map<String, dynamic>?> getUserData() async {
    final jsonStr = await _storage.read(key: _keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Xóa toàn bộ token và phiên đăng nhập khi Logout hoặc nhận lỗi 401
  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyExpiresAt);
    await _storage.delete(key: _keyUserData);
  }
}
