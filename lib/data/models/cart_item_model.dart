/// Model một dòng trong Giỏ hàng lưu trữ Local (SharedPreferences)
class CartItemModel {
  final int productId;
  final int? colorId;
  final String productName;
  final String? imageUrl;
  final String? colorName;
  final double displayPrice; // Giá lúc thêm vào giỏ (dùng để đối chiếu)
  double currentPrice; // Giá mới nhất sau khi fetch lại từ GET /api/products/{id}
  int quantity;
  int maxStock; // Số lượng tồn kho hiện tại từ server
  bool isOutOfStock; // Trạng thái còn hàng hay hết hàng

  CartItemModel({
    required this.productId,
    this.colorId,
    required this.productName,
    this.imageUrl,
    this.colorName,
    required this.displayPrice,
    required this.currentPrice,
    this.quantity = 1,
    this.maxStock = 999,
    this.isOutOfStock = false,
  });

  /// Khóa định danh duy nhất của sản phẩm trong giỏ (kết hợp productId + colorId)
  String get uniqueKey => '${productId}_${colorId ?? 0}';

  /// Kiểm tra xem giá từ server có bị thay đổi so với lúc ban đầu thêm vào giỏ hay không
  bool get hasPriceChanged => (displayPrice - currentPrice).abs() > 0.01;

  /// Tổng tiền của dòng sản phẩm này theo giá mới nhất từ máy chủ
  double get totalPrice => currentPrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final dispPrice = json['displayPrice'] != null
        ? (json['displayPrice'] as num).toDouble()
        : (json['price'] != null ? (json['price'] as num).toDouble() : 0.0);

    final currPrice = json['currentPrice'] != null
        ? (json['currentPrice'] as num).toDouble()
        : dispPrice;

    return CartItemModel(
      productId: json['productId'] != null
          ? (json['productId'] as num).toInt()
          : 0,
      colorId: json['colorId'] != null
          ? (json['colorId'] as num).toInt()
          : null,
      productName: json['productName'] as String? ?? 'Sản phẩm',
      imageUrl: json['imageUrl'] as String?,
      colorName: json['colorName'] as String?,
      displayPrice: dispPrice,
      currentPrice: currPrice,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toInt()
          : 1,
      maxStock: json['maxStock'] != null
          ? (json['maxStock'] as num).toInt()
          : 999,
      isOutOfStock: json['isOutOfStock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'colorId': colorId,
      'productName': productName,
      'imageUrl': imageUrl,
      'colorName': colorName,
      'displayPrice': displayPrice,
      'currentPrice': currentPrice,
      'quantity': quantity,
      'maxStock': maxStock,
      'isOutOfStock': isOutOfStock,
    };
  }

  CartItemModel copyWith({
    double? currentPrice,
    int? quantity,
    int? maxStock,
    bool? isOutOfStock,
  }) {
    return CartItemModel(
      productId: productId,
      colorId: colorId,
      productName: productName,
      imageUrl: imageUrl,
      colorName: colorName,
      displayPrice: displayPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
    );
  }
}
