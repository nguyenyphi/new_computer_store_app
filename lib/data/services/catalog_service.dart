import '../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/paginated_response.dart';
import '../models/product_model.dart';

/// Dịch vụ kết nối API Danh mục và Sản phẩm (Catalog Service)
class CatalogService {
  final ApiClient apiClient;

  CatalogService({required this.apiClient});

  /// Lấy danh sách danh mục sản phẩm: GET /api/categories
  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get('/api/categories');
    if (response is List) {
      return response
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Lấy danh sách sản phẩm phân trang và tìm kiếm:
  /// GET /api/products?categoryId=&q=&page=&pageSize=
  Future<PaginatedResponse<ProductModel>> getProducts({
    int? categoryId,
    String? q,
    int page = 1,
    int pageSize = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };

    if (categoryId != null && categoryId > 0) {
      queryParams['categoryId'] = categoryId;
    }

    if (q != null && q.trim().isNotEmpty) {
      queryParams['q'] = q.trim();
    }

    final response = await apiClient.get(
      '/api/products',
      queryParameters: queryParams,
    );

    return PaginatedResponse<ProductModel>.fromJson(
      response,
      (json) => ProductModel.fromJson(json),
    );
  }

  /// Lấy chi tiết sản phẩm theo ID: GET /api/products/{id}
  Future<ProductModel> getProductById(int productId) async {
    final response = await apiClient.get('/api/products/$productId');
    if (response is Map<String, dynamic>) {
      // Hỗ trợ cả trường hợp server bọc trong { data: { ... } }
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return ProductModel.fromJson(data);
    }
    throw Exception('Dữ liệu sản phẩm trả về không hợp lệ');
  }
}
