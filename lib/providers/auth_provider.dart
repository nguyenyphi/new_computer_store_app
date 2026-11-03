import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// Trạng thái kết quả của thao tác đăng nhập
enum LoginResult {
  success,
  emailNotVerified,
  failed,
}

/// Provider quản lý toàn bộ trạng thái xác thực người dùng (Authentication State)
class AuthProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  String? _lastRegisteredEmail;

  AuthProvider({required this.authRepository});

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  String? get lastRegisteredEmail => _lastRegisteredEmail;

  /// Khởi tạo khi mở app: Kiểm tra Keystore xem có token còn hạn không
  /// Nếu hợp lệ -> tải profile và vào thẳng trang chủ
  Future<void> checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await authRepository.checkAuthStatus();
    } catch (_) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Đăng nhập: POST /api/auth/login
  /// Nếu tài khoản chưa kích hoạt OTP (mã EMAIL_NOT_VERIFIED) -> trả về LoginResult.emailNotVerified
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Gọi API đăng nhập và lưu token
      _currentUser = await authRepository.login(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return LoginResult.success;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;

      // 2. Bắt mã EMAIL_NOT_VERIFIED từ server để chuyển hướng sang màn hình OTP
      if (e.isEmailNotVerified) {
        notifyListeners();
        return LoginResult.emailNotVerified;
      }

      notifyListeners();
      return LoginResult.failed;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra sự cố: $e';
      notifyListeners();
      return LoginResult.failed;
    }
  }

  /// Đăng ký tài khoản sinh viên/khách hàng mới
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      _lastRegisteredEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra sự cố: $e';
      notifyListeners();
      return false;
    }
  }

  /// Xác thực mã OTP 6 số để kích hoạt tài khoản
  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.verifyOtp(
        email: email,
        otpCode: otpCode,
      );
      _lastRegisteredEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra sự cố: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gửi lại mã OTP qua email
  Future<bool> resendOtp({required String email}) async {
    _errorMessage = null;
    try {
      await authRepository.resendOtp(email: email);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không gửi được OTP: $e';
      notifyListeners();
      return false;
    }
  }

  /// Yêu cầu gửi OTP đặt lại mật khẩu khi quên
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.forgotPassword(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra sự cố: $e';
      notifyListeners();
      return false;
    }
  }

  /// Đặt lại mật khẩu mới với OTP
  Future<bool> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.resetPassword(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đã xảy ra sự cố: $e';
      notifyListeners();
      return false;
    }
  }

  /// Tải lại thông tin cá nhân: GET /api/me
  Future<void> loadProfile() async {
    try {
      _currentUser = await authRepository.checkAuthStatus();
      notifyListeners();
    } catch (_) {}
  }

  /// Đăng xuất: xóa token trong Keystore và reset state
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await authRepository.logout();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Xử lý khi nhận 401 từ Interceptor: tự động đăng xuất
  void handleUnauthorized() {
    _currentUser = null;
    _errorMessage = 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
