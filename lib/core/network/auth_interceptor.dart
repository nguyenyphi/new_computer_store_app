import 'package:dio/dio.dart';
import '../../data/services/auth_storage.dart';

/// Interceptor chuyên xử lý việc gắn Token vào Header của mỗi Request
/// và bắt phản hồi 401 Unauthorized từ Backend để tự động đăng xuất người dùng.
class AuthInterceptor extends QueuedInterceptor {
  final AuthStorage authStorage;
  final void Function()? onUnauthorized;

  AuthInterceptor({
    required this.authStorage,
    this.onUnauthorized,
  });

  /// Trước khi gửi Request: Tự động kiểm tra và gắn Access Token vào Header
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Không cần gắn Token cho các endpoint xác thực công khai
    final isAuthPublicEndpoint = options.path.contains('/auth/login') ||
        options.path.contains('/auth/register') ||
        options.path.contains('/auth/verify') ||
        options.path.contains('/auth/resend-otp') ||
        options.path.contains('/auth/forgot-password') ||
        options.path.contains('/auth/reset-password');

    if (!isAuthPublicEndpoint) {
      final token = await authStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  /// Khi nhận phản hồi lỗi từ máy chủ:
  /// Nếu gặp mã 401 (Hết hạn token hoặc không hợp lệ) -> Tự động xóa token và chuyển về màn Đăng nhập.
  /// Lưu ý: Không kích hoạt đăng xuất khi lỗi 401 đến từ chính các endpoint xác thực (như sai mật khẩu ở /auth/login).
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthPublicEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/verify') ||
        path.contains('/auth/resend-otp') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password');

    if (err.response?.statusCode == 401 && !isAuthPublicEndpoint) {
      // 1. Xóa toàn bộ token và thông tin phiên đã lưu trong Keystore
      await authStorage.clearAuthData();

      // 2. Kích hoạt sự kiện đăng xuất để Router điều hướng người dùng về màn Login
      onUnauthorized?.call();
    }

    return handler.next(err);
  }
}
