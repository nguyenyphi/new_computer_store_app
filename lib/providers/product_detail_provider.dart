import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../data/models/product_color_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/catalog_repository.dart';

/// Provider quản lý trạng thái của Màn hình Chi tiết sản phẩm
class ProductDetailProvider extends ChangeNotifier {
  final CatalogRepository catalogRepository;

  ProductModel? _product;
  bool _isLoading = false;
  String? _errorMessage;

  // Biến thể màu sắc đang chọn
  ProductColorModel? _selectedColor;

  // Số lượng mua đang chọn
  int _selectedQuantity = 1;

  // Vị trí ảnh hiện tại trong Gallery PageView
  int _currentImageIndex = 0;

  ProductDetailProvider({required this.catalogRepository});

  ProductModel? get product => _product;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ProductColorModel? get selectedColor => _selectedColor;
  int get selectedQuantity => _selectedQuantity;
  int get currentImageIndex => _currentImageIndex;

  /// Tải thông tin chi tiết sản phẩm: GET /api/products/{id}
  Future<void> loadProductDetail(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedQuantity = 1;
    _currentImageIndex = 0;
    notifyListeners();

    try {
      _product = await catalogRepository.getProductById(productId);

      // Mặc định chọn màu đầu tiên nếu sản phẩm có biến thể màu sắc
      if (_product?.productColors.isNotEmpty ?? false) {
        _selectedColor = _product!.productColors.first;
      } else {
        _selectedColor = null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Không thể tải chi tiết sản phẩm: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Chọn màu sắc sản phẩm
  void selectColor(ProductColorModel color) {
    _selectedColor = color;
    // Đảm bảo số lượng không vượt quá tồn kho của màu được chọn
    final maxStock = color.quantity > 0 ? color.quantity : (_product?.quantity ?? 1);
    if (_selectedQuantity > maxStock) {
      _selectedQuantity = maxStock > 0 ? maxStock : 1;
    }
    notifyListeners();
  }

  /// Cập nhật vị trí ảnh trong Gallery
  void setImageIndex(int index) {
    _currentImageIndex = index;
    notifyListeners();
  }

  /// Tăng số lượng mua (không vượt quá tồn kho)
  void increaseQuantity() {
    final maxStock = _getMaxStock();
    if (_selectedQuantity < maxStock) {
      _selectedQuantity++;
      notifyListeners();
    }
  }

  /// Giảm số lượng mua (tối thiểu là 1)
  void decreaseQuantity() {
    if (_selectedQuantity > 1) {
      _selectedQuantity--;
      notifyListeners();
    }
  }

  /// Lấy giới hạn tồn kho có thể đặt
  int _getMaxStock() {
    if (_selectedColor != null && _selectedColor!.quantity > 0) {
      return _selectedColor!.quantity;
    }
    return _product?.quantity ?? 1;
  }
}
