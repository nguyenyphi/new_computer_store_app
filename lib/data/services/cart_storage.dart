import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item_model.dart';

/// Dịch vụ lưu trữ Giỏ hàng cục bộ (Local Cart) sử dụng SharedPreferences
/// Dữ liệu giỏ hàng được giữ nguyên khi đăng xuất người dùng theo đúng yêu cầu.
class CartStorage {
  static const String _keyCart = 'local_cart_items';

  /// Lưu danh sách giỏ hàng vào SharedPreferences dưới dạng chuỗi JSON
  Future<void> saveCart(List<CartItemModel> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((item) => item.toJson()).toList();
    await prefs.setString(_keyCart, jsonEncode(jsonList));
  }

  /// Đọc danh sách giỏ hàng từ SharedPreferences
  Future<List<CartItemModel>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyCart);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Xóa giỏ hàng cục bộ (sau khi đặt hàng thành công)
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCart);
  }
}
