import 'product_color_model.dart';
import 'spec_group_model.dart';

/// Model sản phẩm máy tính và linh kiện
class ProductModel {
  final int productId;
  final String productName;
  final double price;
  final double discountPercent;
  final double finalPrice;
  final int quantity;
  final String? description;
  final String? imageUrl;
  final List<String> additionalImages;
  final int categoryId;
  final String? categoryName;
  final List<ProductColorModel> productColors;
  final List<SpecGroupModel> specGroups;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.price,
    this.discountPercent = 0.0,
    required this.finalPrice,
    this.quantity = 0,
    this.description,
    this.imageUrl,
    this.additionalImages = const [],
    this.categoryId = 0,
    this.categoryName,
    this.productColors = const [],
    this.specGroups = const [],
  });

  /// Kiểm tra sản phẩm còn hàng hay đã hết hàng
  bool get isOutOfStock => quantity <= 0;

  /// Kiểm tra có áp dụng giảm giá không
  bool get hasDiscount => discountPercent > 0;

  /// Danh sách tất cả hình ảnh phục vụ cho PageView gallery vuốt ngang
  List<String> get allImages {
    final list = <String>[];
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      list.add(imageUrl!.trim());
    }
    for (final img in additionalImages) {
      if (img.trim().isNotEmpty && !list.contains(img.trim())) {
        list.add(img.trim());
      }
    }
    return list;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Luôn ép kiểu số bằng (x as num).toDouble() hoặc (x as num).toInt() theo nguyên tắc bắt buộc
    final double rawPrice = json['price'] != null
        ? (json['price'] as num).toDouble()
        : 0.0;

    final double rawDiscount = json['discountPercent'] != null
        ? (json['discountPercent'] as num).toDouble()
        : 0.0;

    // Nếu server không trả sẵn finalPrice thì tự tính: price - (price * discount / 100)
    final double rawFinalPrice = json['finalPrice'] != null
        ? (json['finalPrice'] as num).toDouble()
        : (rawDiscount > 0 ? (rawPrice * (100 - rawDiscount) / 100) : rawPrice);

    final int rawQuantity = json['quantity'] != null
        ? (json['quantity'] as num).toInt()
        : 0;

    final int rawCategoryId = json['categoryId'] != null
        ? (json['categoryId'] as num).toInt()
        : (json['category'] is Map && json['category']['categoryId'] != null
            ? (json['category']['categoryId'] as num).toInt()
            : 0);

    String? catName = json['categoryName'] as String?;
    if (catName == null && json['category'] is Map) {
      catName = json['category']['categoryName'] as String?;
    }

    // Xử lý danh sách ảnh phụ & gallery
    List<String> addImages = [];
    final rawAddImages = json['additionalImages'] ?? json['galleryImages'];
    if (rawAddImages is List) {
      addImages = rawAddImages
          .map((e) => e.toString())
          .toList();
    } else if (rawAddImages is String && rawAddImages.isNotEmpty) {
      addImages = rawAddImages
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // Xử lý biến thể màu sắc (hỗ trợ cả 'productColors' và 'colors')
    List<ProductColorModel> colors = [];
    final rawColors = json['productColors'] ?? json['colors'];
    if (rawColors is List) {
      colors = rawColors
          .map((e) => ProductColorModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Xử lý nhóm thông số kỹ thuật (SpecGroups hoặc ProductSpecs)
    List<SpecGroupModel> groups = [];
    if (json['specGroups'] is List) {
      groups = (json['specGroups'] as List)
          .map((e) => SpecGroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['productSpecs'] is List) {
      // Hỗ trợ gom nhóm nếu server trả về dạng phẳng productSpecs
      final Map<String, List<SpecKeyModel>> groupedMap = {};
      for (final spec in json['productSpecs']) {
        if (spec is Map<String, dynamic>) {
          final groupName = spec['specKey'] is Map &&
                  spec['specKey']['group'] is Map
              ? spec['specKey']['group']['name'] as String? ?? 'Thông số kỹ thuật'
              : 'Thông số kỹ thuật';
          final keyModel = SpecKeyModel.fromJson(spec);
          groupedMap.putIfAbsent(groupName, () => []).add(keyModel);
        }
      }
      int idx = 1;
      groups = groupedMap.entries.map((entry) {
        return SpecGroupModel(
          id: idx++,
          name: entry.key,
          displayOrder: idx,
          specKeys: entry.value,
        );
      }).toList();
    }

    return ProductModel(
      productId: json['productId'] != null
          ? (json['productId'] as num).toInt()
          : (json['id'] != null ? (json['id'] as num).toInt() : 0),
      productName: json['productName'] as String? ??
          json['name'] as String? ??
          'Sản phẩm',
      price: rawPrice,
      discountPercent: rawDiscount,
      finalPrice: rawFinalPrice,
      quantity: rawQuantity,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      additionalImages: addImages,
      categoryId: rawCategoryId,
      categoryName: catName,
      productColors: colors,
      specGroups: groups,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'discountPercent': discountPercent,
      'finalPrice': finalPrice,
      'quantity': quantity,
      'description': description,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'productColors': productColors.map((e) => e.toJson()).toList(),
      'specGroups': specGroups.map((e) => e.toJson()).toList(),
    };
  }
}
