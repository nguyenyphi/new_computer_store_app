import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình dùng chung của ứng dụng Computer Store.
/// [AppConfig.baseUrl] cung cấp địa chỉ máy chủ API trung tâm cho toàn bộ app.
///
/// Thứ tự ưu tiên xác định Base URL:
/// 1. Địa chỉ người dùng tùy chỉnh và lưu trong SharedPreferences (trong app)
/// 2. Biến môi trường lúc chạy: `--dart-define=BASE_URL=...`
/// 3. Giá trị mặc định hiện tại: `https://widegreytrail12.conveyor.cloud/`
class AppConfig {
  AppConfig._();

  /// Địa chỉ Backend mặc định (Conveyor Tunnel hiện tại)
  static const String defaultBaseUrl = 'https://widegreytrail12.conveyor.cloud/';

  /// Địa chỉ truyền qua tham số runtime: `--dart-define=BASE_URL=...`
  /// Nếu không truyền, mặc định nhận [defaultBaseUrl]
  static const String envBaseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Các địa chỉ cũ không còn dùng, nếu còn lưu trong máy sẽ tự bị xóa
  static const List<String> _obsoleteUrls = [
    'oldorangeapple30',
    'othersparklycard97',
    '192.168.1.57',
    '10.0.2.2',
    'localhost',
  ];

  /// Key lưu trữ SharedPreferences cho địa chỉ tùy chỉnh trong app
  static const String keyCustomBaseUrl = 'custom_server_base_url';

  /// Biến runtime lưu địa chỉ đang áp dụng trong phiên
  static String _currentBaseUrl = envBaseUrl;

  /// Lấy địa chỉ Base URL hiện tại đang sử dụng.
  static String get baseUrl => _currentBaseUrl;

  /// Tên ứng dụng
  static const String appName = 'Computer Store';

  /// Thời gian chờ kết nối (15 giây để ổn định qua Conveyor Tunnel)
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Thời gian chờ nhận phản hồi từ server (20 giây để kịp gửi email OTP SMTP)
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Khởi tạo lấy Base URL hiệu lực từ SharedPreferences khi app khởi động.
  /// Ưu tiên: Saved URL > envBaseUrl (--dart-define) > defaultBaseUrl.
  static Future<String> initEffectiveBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(keyCustomBaseUrl);
    // Bỏ địa chỉ Conveyor cũ đã lưu (link Conveyor đổi mỗi lần backend chạy lại)
    if (savedUrl != null && _obsoleteUrls.any(savedUrl.contains)) {
      await prefs.remove(keyCustomBaseUrl);
      _currentBaseUrl = normalizeUrl(envBaseUrl);
      return _currentBaseUrl;
    }
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
    if (!trimmed.startsWith('https://')) {
      return 'Địa chỉ máy chủ phải bắt đầu bằng https://';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasAuthority) {
      return 'Địa chỉ máy chủ không đúng định dạng URL hợp lệ';
    }
    return null;
  }
}
