import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/catalog_repository.dart';

/// Provider quản lý Danh mục, Tìm kiếm và Lưới sản phẩm phân trang cuộn vô hạn
class CatalogProvider extends ChangeNotifier {
  final CatalogRepository catalogRepository;

  // Categories State
  List<CategoryModel> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;
  int? _selectedCategoryId;

  // Products Pagination State
  List<ProductModel> _products = [];
  bool _isLoadingProducts = false;
  bool _isLoadingMore = false;
  String? _productsError;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchQuery = '';

  // Timer cho tính năng debounce tìm kiếm 400ms
  Timer? _debounceTimer;

  CatalogProvider({required this.catalogRepository});

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;
  int? get selectedCategoryId => _selectedCategoryId;

  List<ProductModel> get products => _products;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingMore => _isLoadingMore;
  String? get productsError => _productsError;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;

  /// Tải danh sách danh mục: GET /api/categories
  Future<void> loadCategories() async {
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();

    try {
      _categories = await catalogRepository.getCategories();
    } on ApiException catch (e) {
      _categoriesError = e.message;
    } catch (e) {
      _categoriesError = 'Không thể tải danh mục: $e';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Chọn danh mục (hoặc bỏ chọn để xem tất cả)
  void selectCategory(int? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // Bỏ chọn nếu bấm lại
    } else {
      _selectedCategoryId = categoryId;
    }
    notifyListeners();
    loadProducts(refresh: true);
  }

  /// Tìm kiếm với Debounce 400ms theo đúng yêu cầu
  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_searchQuery != query) {
        _searchQuery = query;
        loadProducts(refresh: true);
      }
    });
  }

  /// Xóa tìm kiếm
  void clearSearch() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _searchQuery = '';
    loadProducts(refresh: true);
  }

  /// Tải danh sách sản phẩm (trang đầu tiên hoặc làm mới)
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final response = await catalogRepository.getProducts(
        categoryId: _selectedCategoryId,
        q: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
        pageSize: _pageSize,
      );

      _products = response.items;
      _hasMore = response.hasMore;
      _currentPage = response.page;
    } on ApiException catch (e) {
      _productsError = e.message;
    } catch (e) {
      _productsError = 'Không thể tải danh sách sản phẩm: $e';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Tải thêm sản phẩm khi cuộn đến cuối màn hình (Infinite Scroll)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoadingProducts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await catalogRepository.getProducts(
        categoryId: _selectedCategoryId,
        q: _searchQuery.isEmpty ? null : _searchQuery,
        page: nextPage,
        pageSize: _pageSize,
      );

      _products.addAll(response.items);
      _currentPage = response.page;
      _hasMore = response.hasMore;
    } catch (_) {
      // Giữ nguyên danh sách hiện tại nếu tải trang tiếp theo lỗi
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Kéo để làm mới toàn bộ trang chủ (Pull to Refresh)
  Future<void> refreshAll() async {
    await Future.wait([
      loadCategories(),
      loadProducts(refresh: true),
    ]);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
