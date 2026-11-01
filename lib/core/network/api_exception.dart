import 'package:dio/dio.dart';

/// Class xử lý ngoại lệ API tập trung, hỗ trợ chuẩn ProblemDetails (RFC 7807)
/// từ ASP.NET Core: các trường "code", "title", "detail", "status", "errors".
class ApiException implements Exception {
  final int? statusCode;
  final String? code;
  final String? title;
  final String? detail;
  final Map<String, List<String>>? validationErrors;
  final String message;

  ApiException({
    this.statusCode,
    this.code,
    this.title,
    this.detail,
    this.validationErrors,
    required this.message,
  });

  /// Factory chuyển đổi DioException thành ApiException với thông báo tiếng Việt
  factory ApiException.fromDioException(DioException dioException) {
    int? statusCode = dioException.response?.statusCode;
    String? code;
    String? title;
    String? detail;
    Map<String, List<String>>? validationErrors;

    final responseData = dioException.response?.data;

    // Parse nội dung ProblemDetails nếu server trả về dạng Map/JSON
    if (responseData is Map<String, dynamic>) {
      code = responseData['code'] as String?;
      title = responseData['title'] as String?;
      detail = responseData['detail'] as String?;

      // Parse danh sách lỗi xác thực (nếu có trường "errors")
      if (responseData['errors'] is Map<String, dynamic>) {
        validationErrors = {};
        final rawErrors = responseData['errors'] as Map<String, dynamic>;
        rawErrors.forEach((key, value) {
          if (value is List) {
            validationErrors![key] = value.map((e) => e.toString()).toList();
          } else if (value is String) {
            validationErrors![key] = [value];
          }
        });
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      detail = responseData;
    }

    // Xác định thông báo hiển thị tiếng Việt thân thiện dựa trên kiểu lỗi và HTTP status
    String vietnameseMessage;

    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        // Lỗi mạng hoặc không kết nối được tới máy chủ LAN
        vietnameseMessage =
            'Không kết nối được máy chủ, kiểm tra Wi-Fi và địa chỉ server ($statusCode).';
        break;

      case DioExceptionType.badResponse:
        vietnameseMessage = _getBadResponseMessage(
          statusCode: statusCode,
          code: code,
          title: title,
          detail: detail,
          validationErrors: validationErrors,
        );
        break;

      case DioExceptionType.cancel:
        vietnameseMessage = 'Yêu cầu kết nối đã bị hủy.';
        break;

      default:
        vietnameseMessage =
            detail ?? 'Đã xảy ra lỗi không xác định. Vui lòng thử lại sau.';
        break;
    }

    return ApiException(
      statusCode: statusCode,
      code: code,
      title: title,
      detail: detail,
      validationErrors: validationErrors,
      message: vietnameseMessage,
    );
  }

  /// Xử lý thông điệp cho các mã lỗi HTTP (401, 403, 404, 409, 5xx...)
  static String _getBadResponseMessage({
    int? statusCode,
    String? code,
    String? title,
    String? detail,
    Map<String, List<String>>? validationErrors,
  }) {
    // Nếu có lỗi validation chi tiết từ model state, gom các lỗi lại
    if (validationErrors != null && validationErrors.isNotEmpty) {
      final firstKey = validationErrors.keys.first;
      final firstErrorList = validationErrors[firstKey];
      if (firstErrorList != null && firstErrorList.isNotEmpty) {
        return firstErrorList.first;
      }
    }

    // Ưu tiên detail hoặc title từ máy chủ gửi về nếu có
    if (detail != null && detail.trim().isNotEmpty) {
      return detail;
    }
    if (title != null && title.trim().isNotEmpty) {
      return title;
    }

    // Các thông báo mặc định theo HTTP Status Code
    switch (statusCode) {
      case 400:
        return 'Yêu cầu không hợp lệ. Vui lòng kiểm tra lại thông tin.';
      case 401:
        return 'Phiên đăng nhập đã hết hạn hoặc bạn chưa đăng nhập.';
      case 403:
        return 'Bạn không có quyền thực hiện thao tác này.';
      case 404:
        return 'Không tìm thấy dữ liệu yêu cầu trên máy chủ.';
      case 409:
        return 'Dữ liệu bị xung đột hoặc đã tồn tại trong hệ thống.';
      case 422:
        return 'Dữ liệu gửi lên không đúng định dạng yêu cầu.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Máy chủ đang gặp sự cố (mã $statusCode), vui lòng thử lại sau.';
      default:
        return 'Đã xảy ra lỗi phản hồi từ máy chủ (mã $statusCode).';
    }
  }

  /// Kiểm tra có phải lỗi do chưa xác thực email hay không
  bool get isEmailNotVerified =>
      code == 'EMAIL_NOT_VERIFIED' ||
      (detail?.toUpperCase().contains('EMAIL_NOT_VERIFIED') ?? false);

  @override
  String toString() => message;
}
