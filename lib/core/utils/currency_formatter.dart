import 'package:intl/intl.dart';

/// Tiện ích định dạng tiền tệ Việt Nam Đồng dùng chung cho toàn bộ ứng dụng.
/// Kết quả mẫu: "1.234.000 ₫" hoặc "0 ₫".
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Định dạng số (num/double/int) thành chuỗi tiền tệ tiếng Việt: "1.234.000 ₫"
  static String format(num? amount) {
    if (amount == null) return '0 ₫';
    return _formatter.format(amount).trim();
  }
}
