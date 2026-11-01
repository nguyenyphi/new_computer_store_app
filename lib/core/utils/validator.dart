/// Lớp kiểm tra dữ liệu đầu vào (Validation) cho các form nhập liệu
class FormValidators {
  FormValidators._();

  /// Kiểm tra họ tên không để trống
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (value.trim().length < 2) {
      return 'Họ và tên phải có ít nhất 2 ký tự';
    }
    return null;
  }

  /// Kiểm tra định dạng Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ email';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Địa chỉ email không đúng định dạng';
    }
    return null;
  }

  /// Kiểm tra mật khẩu
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải chứa ít nhất 6 ký tự';
    }
    return null;
  }

  /// Kiểm tra xác nhận mật khẩu
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != originalPassword) {
      return 'Mật khẩu xác nhận không trùng khớp';
    }
    return null;
  }

  /// Kiểm tra mã OTP gồm 6 chữ số
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập mã OTP';
    }
    if (value.trim().length != 6 || int.tryParse(value.trim()) == null) {
      return 'Mã OTP phải gồm 6 chữ số';
    }
    return null;
  }
}
