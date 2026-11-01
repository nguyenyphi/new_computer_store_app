/// Model danh mục sản phẩm (Category)
class CategoryModel {
  final int categoryId;
  final String categoryName;
  final int productCount;
  final String? imageUrl;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    this.productCount = 0,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['categoryId'] != null
          ? (json['categoryId'] as num).toInt()
          : (json['id'] != null ? (json['id'] as num).toInt() : 0),
      categoryName: json['categoryName'] as String? ??
          json['name'] as String? ??
          'Danh mục',
      productCount: json['productCount'] != null
          ? (json['productCount'] as num).toInt()
          : 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'productCount': productCount,
      'imageUrl': imageUrl,
    };
  }
}
