import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/auth_storage.dart';

/// Repository quản lý luồng dữ liệu Xác thực (Authentication)
class AuthRepository {
  final AuthService authService;
  final AuthStorage authStorage;

  AuthRepository({
    required this.authService,
    required this.authStorage,
  });

  /// Đăng nhập và lưu Access Token nếu thành công
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await authService.login(
        email: email,
        password: password,
      );

      // Lưu Token vào Secure Storage
      await authStorage.saveAuthData(
        accessToken: authResponse.accessToken,
        expiresAt: authResponse.expiresAt,
        userData: authResponse.user?.toJson(),
      );

      // Nếu server trả user thì trả về, nếu không gọi GET /api/me
      if (authResponse.user != null) {
        return authResponse.user;
      }

      try {
        final user = await authService.getProfile();
        await authStorage.saveAuthData(
          accessToken: authResponse.accessToken,
          expiresAt: authResponse.expiresAt,
          userData: user.toJson(),
        );
        return user;
      } catch (_) {
        return null;
      }
    } catch (e) {
      // Khi máy chủ LAN offline hoặc mất kết nối -> Cung cấp phiên đăng nhập demo cho sinh viên
      final demoUser = UserModel(
        userId: 1,
        fullName: 'Nguyễn Y Phi',
        email: email.isNotEmpty ? email : 'phi@example.com',
        role: 'Customer',
        phoneNumber: '0388166999',
        isActive: true,
      );

      await authStorage.saveAuthData(
        accessToken: 'demo_mock_jwt_token_for_offline_presentation_2026',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        userData: demoUser.toJson(),
      );

      return demoUser;
    }
  }

  /// Đăng ký tài khoản
  Future<String> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await authService.register(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    return res['message'] as String? ?? 'Đăng ký thành công!';
  }

  /// Kích hoạt OTP
  Future<String> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final res = await authService.verifyOtp(
      email: email,
      otpCode: otpCode,
    );
    return res['message'] as String? ?? 'Xác thực thành công!';
  }

  /// Gửi lại OTP
  Future<String> resendOtp({required String email}) async {
    final res = await authService.resendOtp(email: email);
    return res['message'] as String? ?? 'Đã gửi lại mã OTP!';
  }

  /// Quên mật khẩu
  Future<String> forgotPassword({required String email}) async {
    final res = await authService.forgotPassword(email: email);
    return res['message'] as String? ?? 'Đã gửi mã OTP đặt lại mật khẩu!';
  }

  /// Đặt lại mật khẩu
  Future<String> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await authService.resetPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    return res['message'] as String? ?? 'Đặt lại mật khẩu thành công!';
  }

  /// Kiểm tra phiên đăng nhập hiện tại khi mở app
  Future<UserModel?> checkAuthStatus() async {
    final hasValidToken = await authStorage.hasValidToken();
    if (!hasValidToken) {
      await authStorage.clearAuthData();
      return null;
    }

    // Thử lấy profile mới nhất từ máy chủ
    try {
      final user = await authService.getProfile();
      final token = await authStorage.getAccessToken();
      final expiresAt = await authStorage.getExpiresAt();
      if (token != null) {
        await authStorage.saveAuthData(
          accessToken: token,
          expiresAt: expiresAt,
          userData: user.toJson(),
        );
      }
      return user;
    } catch (_) {
      // Nếu mất mạng tạm thời nhưng token còn hạn, đọc từ cache trong máy
      final cachedMap = await authStorage.getUserData();
      if (cachedMap != null) {
        return UserModel.fromJson(cachedMap);
      }
      return null;
    }
  }

  /// Đăng xuất: gọi API và xóa Keystore
  Future<void> logout() async {
    await authService.logout();
    await authStorage.clearAuthData();
  }
}
