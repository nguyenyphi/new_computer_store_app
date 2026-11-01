import 'package:flutter/material.dart';
import '../data/models/cart_item_model.dart';
import '../data/models/product_color_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/services/cart_storage.dart';

/// Provider quản lý Giỏ hàng lưu trữ Local (SharedPreferences)
/// Tự động làm mới giá & tồn kho từ GET /api/products/{id} khi vào giỏ hàng / checkout.
class CartProvider extends ChangeNotifier {
  final CartStorage cartStorage;

  List<CartItemModel> _items = [];
  bool _isRefreshingPrices = false;
  bool _hasPriceChangedNotice = false;

  CartProvider({required this.cartStorage}) {
    loadCart();
  }

  List<CartItemModel> get items => _items;
  bool get isRefreshingPrices => _isRefreshingPrices;
  bool get hasPriceChangedNotice => _hasPriceChangedNotice;

  /// Tổng số lượng mặt hàng (hiển thị trên Badge của tab Giỏ hàng)
  int get totalItemsCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  /// Tổng tiền tạm tính của toàn bộ giỏ hàng (chỉ tính những sản phẩm còn hàng)
  double get totalAmount => _items
      .where((item) => !item.isOutOfStock)
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Khởi tạo và đọc giỏ hàng từ SharedPreferences
  Future<void> loadCart() async {
    _items = await cartStorage.getCart();
    notifyListeners();
  }

  /// Thêm sản phẩm vào giỏ hàng:
  /// Nếu cùng productId và colorId thì CỘNG DỒN số lượng, chặn vượt tồn kho.
  Future<bool> addToCart({
    required ProductModel product,
    ProductColorModel? color,
    int quantity = 1,
  }) async {
    final key = '${product.productId}_${color?.id ?? 0}';
    final existingIndex = _items.indexWhere((item) => item.uniqueKey == key);

    // Xác định tồn kho tối đa cho biến thể màu hoặc sản phẩm chính
    final int stockLimit = color != null && color.quantity > 0
        ? color.quantity
        : product.quantity;

    if (stockLimit <= 0) return false;

    if (existingIndex >= 0) {
      // Đã có trong giỏ -> Cộng dồn số lượng
      final currentItem = _items[existingIndex];
      final newQuantity = currentItem.quantity + quantity;

      if (newQuantity > stockLimit) {
        currentItem.quantity = stockLimit; // Chặn không cho vượt tồn kho
      } else {
        currentItem.quantity = newQuantity;
      }
      currentItem.maxStock = stockLimit;
      currentItem.isOutOfStock = stockLimit <= 0;
    } else {
      // Chưa có trong giỏ -> Thêm dòng mới
      final newItem = CartItemModel(
        productId: product.productId,
        colorId: color?.id,
        productName: product.productName,
        imageUrl: color?.imageUrl ?? product.imageUrl,
        colorName: color?.colorName,
        displayPrice: product.finalPrice,
        currentPrice: product.finalPrice,
        quantity: quantity > stockLimit ? stockLimit : quantity,
        maxStock: stockLimit,
        isOutOfStock: stockLimit <= 0,
      );
      _items.add(newItem);
    }

    await cartStorage.saveCart(_items);
    notifyListeners();
    return true;
  }

  /// Làm mới giá, tồn kho và trạng thái còn hàng từ máy chủ GET /api/products/{id}
  /// Được gọi tự động khi vào màn hình Giỏ hàng hoặc màn hình Checkout
  Future<void> refreshCartPrices(CatalogRepository catalogRepo) async {
    if (_items.isEmpty) return;

    _isRefreshingPrices = true;
    _hasPriceChangedNotice = false;
    notifyListeners();

    try {
      bool priceChanged = false;

      for (final item in _items) {
        try {
          final product = await catalogRepo.getProductById(item.productId);

          // Cập nhật giá mới nhất
          if ((item.currentPrice - product.finalPrice).abs() > 0.01) {
            item.currentPrice = product.finalPrice;
            priceChanged = true;
          }

          // Cập nhật tồn kho mới nhất
          int stockLimit = product.quantity;
          if (item.colorId != null) {
            final colorVariant = product.productColors.firstWhere(
              (c) => c.id == item.colorId,
              orElse: () => ProductColorModel(
                id: item.colorId!,
                productId: item.productId,
                colorName: item.colorName ?? '',
                colorCode: '',
                quantity: 0,
              ),
            );
            stockLimit = colorVariant.quantity;
          }

          item.maxStock = stockLimit;
          item.isOutOfStock = stockLimit <= 0 || product.isOutOfStock;

          // Nếu số lượng trong giỏ hiện tại vượt tồn kho mới -> Tự điều chỉnh giảm
          if (item.quantity > stockLimit && stockLimit > 0) {
            item.quantity = stockLimit;
          }
        } catch (_) {
          // Nếu gặp lỗi mạng tạm thời thì giữ nguyên dữ liệu đã lưu
        }
      }

      _hasPriceChangedNotice = priceChanged;
      await cartStorage.saveCart(_items);
    } finally {
      _isRefreshingPrices = false;
      notifyListeners();
    }
  }

  /// Tăng hoặc giảm số lượng: chặn không vượt quá tồn kho (maxStock)
  Future<void> updateQuantity(int productId, int? colorId, int delta) async {
    final key = '${productId}_${colorId ?? 0}';
    final index = _items.indexWhere((item) => item.uniqueKey == key);
    if (index < 0) return;

    final item = _items[index];
    final newQty = item.quantity + delta;

    if (newQty <= 0) {
      _items.removeAt(index);
    } else if (newQty <= item.maxStock) {
      item.quantity = newQty;
    } else {
      // Đã chạm giới hạn tồn kho tối đa
      item.quantity = item.maxStock;
    }

    await cartStorage.saveCart(_items);
    notifyListeners();
  }

  /// Xóa một mặt hàng khỏi giỏ
  Future<void> removeFromCart(int productId, int? colorId) async {
    final key = '${productId}_${colorId ?? 0}';
    _items.removeWhere((item) => item.uniqueKey == key);
    await cartStorage.saveCart(_items);
    notifyListeners();
  }

  /// Xóa toàn bộ giỏ hàng (sau khi đặt hàng thành công)
  Future<void> clearCart() async {
    _items.clear();
    _hasPriceChangedNotice = false;
    await cartStorage.clearCart();
    notifyListeners();
  }
}
