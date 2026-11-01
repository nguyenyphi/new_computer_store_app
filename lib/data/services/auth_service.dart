import '../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Dịch vụ kết nối API Xác thực & Tài khoản theo đúng tài liệu docs/API.md
class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  /// Đăng nhập tài khoản: POST /api/auth/login
  /// Nếu tài khoản chưa kích hoạt OTP, server trả lỗi kèm code: EMAIL_NOT_VERIFIED
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response as Map<String, dynamic>);
  }

  /// Đăng ký tài khoản mới: POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await apiClient.post(
      '/api/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    return (response is Map<String, dynamic>) ? response : {};
  }

  /// Xác thực mã OTP kích hoạt tài khoản: POST /api/auth/verify-otp (hỗ trợ fallback /api/auth/verify-email)
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/auth/verify-otp',
        data: {
          'email': email,
          'otpCode': otpCode,
        },
      );
      return (response is Map<String, dynamic>) ? response : {};
    } catch (e) {
      // Fallback endpoint nếu backend dùng verify-email
      final response = await apiClient.post(
        '/api/auth/verify-email',
        data: {
          'email': email,
          'otpCode': otpCode,
        },
      );
      return (response is Map<String, dynamic>) ? response : {};
    }
  }

  /// Gửi lại mã OTP: POST /api/auth/resend-otp
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    final response = await apiClient.post(
      '/api/auth/resend-otp',
      data: {
        'email': email,
      },
    );
    return (response is Map<String, dynamic>) ? response : {};
  }

  /// Yêu cầu quên mật khẩu: POST /api/auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await apiClient.post(
      '/api/auth/forgot-password',
      data: {
        'email': email,
      },
    );
    return (response is Map<String, dynamic>) ? response : {};
  }

  /// Đặt lại mật khẩu với mã OTP: POST /api/auth/reset-password
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await apiClient.post(
      '/api/auth/reset-password',
      data: {
        'email': email,
        'otpCode': otpCode,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
    return (response is Map<String, dynamic>) ? response : {};
  }

  /// Lấy thông tin người dùng hiện tại: GET /api/me
  Future<UserModel> getProfile() async {
    final response = await apiClient.get('/api/me');
    return UserModel.fromJson(response as Map<String, dynamic>);
  }

  /// Đăng xuất tài khoản: POST /api/auth/logout
  Future<void> logout() async {
    try {
      await apiClient.post('/api/auth/logout');
    } catch (_) {
      // Bỏ qua lỗi kết nối khi logout phía client
    }
  }
}
