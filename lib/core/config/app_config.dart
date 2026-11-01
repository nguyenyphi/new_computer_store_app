import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình dùng chung của ứng dụng Computer Store.
/// [AppConfig.baseUrl] cung cấp địa chỉ máy chủ API trung tâm cho toàn bộ app.
///
/// Thứ tự ưu tiên xác định Base URL:
/// 1. Địa chỉ người dùng tùy chỉnh và lưu trong SharedPreferences (trong app)
/// 2. Biến môi trường lúc chạy: `--dart-define=BASE_URL=...`
/// 3. Giá trị mặc định hiện tại: `https://oldorangeapple30.conveyor.cloud/`
class AppConfig {
  AppConfig._();

  /// Địa chỉ Backend mặc định (Conveyor Tunnel hiện tại)
  static const String defaultBaseUrl = 'https://oldorangeapple30.conveyor.cloud/';

  /// Địa chỉ truyền qua tham số runtime: `--dart-define=BASE_URL=...`
  /// Nếu không truyền, mặc định nhận [defaultBaseUrl]
  static const String envBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Key lưu trữ SharedPreferences cho địa chỉ tùy chỉnh trong app
  static const String keyCustomBaseUrl = 'custom_server_base_url';

  /// Biến runtime lưu địa chỉ đang áp dụng trong phiên
  static String _currentBaseUrl = envBaseUrl;

  /// Lấy địa chỉ Base URL hiện tại đang sử dụng.
  static String get baseUrl => _currentBaseUrl;

  /// Tên ứng dụng
  static const String appName = 'Computer Store';

  /// Thời gian chờ kết nối (5 giây)
  static const Duration connectTimeout = Duration(seconds: 5);

  /// Thời gian chờ nhận phản hồi từ server (8 giây)
  static const Duration receiveTimeout = Duration(seconds: 8);

  /// Khởi tạo lấy Base URL hiệu lực từ SharedPreferences khi app khởi động.
  /// Ưu tiên: Saved URL > envBaseUrl (--dart-define) > defaultBaseUrl.
  static Future<String> initEffectiveBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(keyCustomBaseUrl);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _currentBaseUrl = normalizeUrl(savedUrl);
    } else {
      _currentBaseUrl = normalizeUrl(envBaseUrl);
    }
    return _currentBaseUrl;
  }

  /// Lưu địa chỉ máy chủ tùy chỉnh vào SharedPreferences và cập nhật runtime
  static Future<void> saveCustomBaseUrl(String url) async {
    final normalized = normalizeUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyCustomBaseUrl, normalized);
    _currentBaseUrl = normalized;
  }

  /// Đặt lại địa chỉ máy chủ về mặc định (hoặc từ --dart-define nếu có)
  static Future<void> resetDefaultBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyCustomBaseUrl);
    _currentBaseUrl = normalizeUrl(envBaseUrl);
  }

  /// Kiểm tra xem người dùng có đang dùng địa chỉ tùy chỉnh hay không
  static Future<bool> hasCustomBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(keyCustomBaseUrl);
    return saved != null && saved.trim().isNotEmpty;
  }

  /// Chuẩn hóa URL: loại bỏ khoảng trắng thừa và tự động thêm dấu "/" ở cuối nếu thiếu
  static String normalizeUrl(String input) {
    var trimmed = input.trim();
    if (!trimmed.endsWith('/')) {
      trimmed = '$trimmed/';
    }
    return trimmed;
  }

  /// Kiểm tra tính hợp lệ của địa chỉ URL: phải bắt đầu bằng https:// hoặc http://
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ máy chủ';
    }
    final trimmed = value.trim();
    if (!trimmed.startsWith('https://') && !trimmed.startsWith('http://')) {
      return 'Địa chỉ máy chủ phải bắt đầu bằng https:// hoặc http://';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority) {
      return 'Địa chỉ máy chủ không đúng định dạng URL hợp lệ';
    }
    return null;
  }
}
