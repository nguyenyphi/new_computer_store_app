import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../../data/services/auth_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Lớp giao tiếp mạng trung tâm (Network Client) sử dụng thư viện Dio.
/// Tự động cấu hình Base URL, Timeout, Interceptor và chuyển đổi lỗi sang ApiException.
class ApiClient {
  late final Dio _dio;
  final AuthStorage authStorage;

  ApiClient({
    required this.authStorage,
    void Function()? onUnauthorized,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    // Thêm Interceptor quản lý xác thực và token
    _dio.interceptors.add(
      AuthInterceptor(
        authStorage: authStorage,
        onUnauthorized: onUnauthorized,
      ),
    );
  }

  /// Phương thức GET dùng chung
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Đã xảy ra lỗi không mong muốn: $e',
      );
    }
  }

  /// Phương thức POST dùng chung
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Đã xảy ra lỗi không mong muốn: $e',
      );
    }
  }

  /// Phương thức PUT dùng chung
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Đã xảy ra lỗi không mong muốn: $e',
      );
    }
  }

  /// Phương thức DELETE dùng chung
  Future<dynamic> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(
        message: 'Đã xảy ra lỗi không mong muốn: $e',
      );
    }
  }

  /// Cập nhật Base URL của Dio ngay lập tức trong phiên mà không cần khởi động lại app
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = AppConfig.normalizeUrl(newBaseUrl);
  }

  /// Địa chỉ Base URL hiện tại đang sử dụng trong Dio instance
  String get currentBaseUrl => _dio.options.baseUrl;

  /// Kiểm tra kết nối tới địa chỉ máy chủ chỉ định: gọi GET {address}api/categories
  /// Trả về kết quả kiểm tra và thông điệp tiếng Việt cụ thể
  static Future<({bool success, String message})> testConnection(String address) async {
    final validationError = AppConfig.validateUrl(address);
    if (validationError != null) {
      return (success: false, message: validationError);
    }

    final normalized = AppConfig.normalizeUrl(address);
    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    try {
      final response = await dio.get('api/categories');
      if (response.statusCode == 200) {
        return (
          success: true,
          message: 'Kết nối thành công! Máy chủ phản hồi dữ liệu bình thường.',
        );
      } else {
        return (
          success: false,
          message: 'Máy chủ phản hồi mã lỗi: ${response.statusCode} ${response.statusMessage ?? ""}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout) {
        return (
          success: false,
          message: 'Hết thời gian chờ kết nối (Timeout). Máy chủ phản hồi quá lâu.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        return (
          success: false,
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại địa chỉ URL hoặc mạng.',
        );
      } else if (e.response?.statusCode != null) {
        return (
          success: false,
          message: 'Máy chủ trả về mã HTTP ${e.response!.statusCode}.',
        );
      }
      return (
        success: false,
        message: 'Lỗi kết nối: ${e.message ?? "Không thể kết nối đến máy chủ."}',
      );
    } catch (e) {
      return (
        success: false,
        message: 'Đã xảy ra lỗi khi kiểm tra kết nối: $e',
      );
    }
  }
}
