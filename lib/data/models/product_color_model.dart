/// Model biến thể màu sắc sản phẩm
class ProductColorModel {
  final int id;
  final int productId;
  final String colorName;
  final String colorCode;
  final int quantity;
  final String? imageUrl;

  ProductColorModel({
    required this.id,
    required this.productId,
    required this.colorName,
    required this.colorCode,
    required this.quantity,
    this.imageUrl,
  });

  factory ProductColorModel.fromJson(Map<String, dynamic> json) {
    return ProductColorModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : 0,
      productId: json['productId'] != null
          ? (json['productId'] as num).toInt()
          : 0,
      colorName: json['colorName'] as String? ?? 'Mặc định',
      colorCode: json['colorCode'] as String? ?? '#000000',
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toInt()
          : 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'colorName': colorName,
      'colorCode': colorCode,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}
