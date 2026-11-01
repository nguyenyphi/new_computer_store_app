import '../mock/mock_data.dart';
import '../models/category_model.dart';
import '../models/paginated_response.dart';
import '../models/product_model.dart';
import '../services/catalog_service.dart';

/// Repository quản lý danh mục và sản phẩm
/// Hỗ trợ tự động chuyển sang dữ liệu mẫu công nghệ (MockData) khi máy chủ backend offline,
/// đảm bảo đồ án luôn sẵn sàng hiển thị đầy đủ danh mục và sản phẩm để demo.
class CatalogRepository {
  final CatalogService catalogService;

  CatalogRepository({required this.catalogService});

  /// Lấy danh sách danh mục (Ưu tiên API Backend, tự động fallback sang MockData khi mất mạng)
  Future<List<CategoryModel>> getCategories() async {
    try {
      final remoteCategories = await catalogService.getCategories();
      if (remoteCategories.isNotEmpty) {
        return remoteCategories;
      }
    } catch (_) {
      // Khi máy chủ backend LAN offline -> Dùng dữ liệu danh mục mẫu
    }
    return MockData.categories;
  }

  /// Lấy danh sách sản phẩm phân trang (Ưu tiên API Backend, tự động fallback khi mất mạng)
  Future<PaginatedResponse<ProductModel>> getProducts({
    int? categoryId,
    String? q,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await catalogService.getProducts(
        categoryId: categoryId,
        q: q,
        page: page,
        pageSize: pageSize,
      );
      if (response.items.isNotEmpty || (q != null && q.isNotEmpty)) {
        return response;
      }
    } catch (_) {
      // Khi máy chủ backend LAN offline -> Dùng dữ liệu sản phẩm mẫu
    }
    return MockData.filterProducts(
      categoryId: categoryId,
      q: q,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Lấy chi tiết sản phẩm (Ưu tiên API Backend, tự động fallback khi mất mạng)
  Future<ProductModel> getProductById(int productId) async {
    try {
      return await catalogService.getProductById(productId);
    } catch (_) {
      final mock = MockData.findProductById(productId);
      if (mock != null) return mock;
      rethrow;
    }
  }
}
