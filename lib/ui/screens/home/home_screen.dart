import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';

/// Màn hình Trang chủ: Tìm kiếm (debounce 400ms), Danh mục, Lưới sản phẩm cuộn vô hạn
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final catalog = context.read<CatalogProvider>();
    // Tải dữ liệu ban đầu nếu chưa có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (catalog.categories.isEmpty) {
        catalog.loadCategories();
      }
      if (catalog.products.isEmpty) {
        catalog.loadProducts();
      }
    });

    // Lắng nghe sự kiện cuộn để tự động tải thêm trang tiếp theo (Infinite Scroll)
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<CatalogProvider>().loadMoreProducts();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.primaryDark : AppColors.primary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.computer_rounded,
                color: isDark ? AppColors.primaryDark : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Cửa Hàng Máy Tính',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chuyển chế độ giao diện',
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => catalog.refreshAll(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Ô tìm kiếm với debounce 400ms
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SearchBarWidget(
                  initialValue: catalog.searchQuery,
                  onChanged: (val) => catalog.onSearchChanged(val),
                  onClear: () => catalog.clearSearch(),
                ),
              ),
            ),

            // 2. Banner khuyến mãi công nghệ
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 125,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1B2A4A), const Color(0xFF0F62FE)]
                          : [const Color(0xFF0F62FE), const Color(0xFF00B4D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -15,
                        child: Icon(
                          Icons.laptop_chromebook,
                          size: 140,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ƯU ĐÃI SINH VIÊN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Laptop & Gaming Giảm Đến 30%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bảo hành chính hãng, miễn phí cài đặt',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Danh sách Danh mục (Horizontal Chips)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Danh mục sản phẩm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (catalog.isLoadingCategories && catalog.categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (catalog.categoriesError != null &&
                      catalog.categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text(
                            'Chưa tải được danh mục',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => catalog.loadCategories(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                            ),
                            child: const Text(
                              'Tải lại',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          // Chip "Tất cả"
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: const Text('Tất cả'),
                              selected: catalog.selectedCategoryId == null,
                              onSelected: (_) => catalog.selectCategory(null),
                            ),
                          ),
                          // Các chip danh mục từ API
                          ...catalog.categories.map((cat) {
                            final isSelected =
                                catalog.selectedCategoryId == cat.categoryId;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(cat.categoryName),
                                selected: isSelected,
                                onSelected: (_) =>
                                    catalog.selectCategory(cat.categoryId),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 4. Tiêu đề mục Danh sách sản phẩm
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      catalog.searchQuery.isNotEmpty
                          ? 'Kết quả: "${catalog.searchQuery}"'
                          : (catalog.selectedCategoryId != null
                              ? 'Sản phẩm theo danh mục'
                              : 'Tất cả sản phẩm'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (catalog.products.isNotEmpty)
                      Text(
                        '${catalog.products.length} sản phẩm',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 5. Nội dung Lưới sản phẩm hoặc Trạng thái Loading / Lỗi / Rỗng
            if (catalog.isLoadingProducts && catalog.products.isEmpty)
              const SliverFillRemaining(
                child: LoadingView(message: 'Đang tải danh sách sản phẩm...'),
              )
            else if (catalog.productsError != null && catalog.products.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: catalog.productsError!,
                  onRetry: () => catalog.refreshAll(),
                ),
              )
            else if (catalog.products.isEmpty)
              SliverFillRemaining(
                child: EmptyView(
                  title: 'Không tìm thấy sản phẩm',
                  message: catalog.searchQuery.isNotEmpty
                      ? 'Không có sản phẩm nào khớp với "${catalog.searchQuery}"'
                      : 'Chưa có sản phẩm nào trong danh mục này.',
                  onAction: () {
                    catalog.clearSearch();
                    catalog.selectCategory(null);
                  },
                  actionLabel: 'Xem tất cả sản phẩm',
                ),
              )
            else ...[
              // Lưới 2 cột hiển thị các sản phẩm
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.65, // Tỷ lệ chuẩn cho Card công nghệ
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = catalog.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          // Điều hướng tới màn hình chi tiết sản phẩm
                          context.push('/product/${product.productId}');
                        },
                      );
                    },
                    childCount: catalog.products.length,
                  ),
                ),
              ),

              // Loading ở cuối danh sách khi đang cuộn vô hạn
              if (catalog.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ),

              // Khoảng đệm dưới cùng
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'chatbot_fab',
        onPressed: () => context.push('/chatbot'),
        icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
        label: const Text(
          'Trợ lý AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
      ),
    );
  }
}
