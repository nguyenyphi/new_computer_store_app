import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';

/// Màn hình Danh mục chuyên sâu (Catalog Screen)
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh Mục Sản Phẩm'),
      ),
      body: RefreshIndicator(
        onRefresh: () => catalog.refreshAll(),
        child: Column(
          children: [
            // Ô tìm kiếm
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: SearchBarWidget(
                initialValue: catalog.searchQuery,
                onChanged: (val) => catalog.onSearchChanged(val),
                onClear: () => catalog.clearSearch(),
              ),
            ),

            // Danh sách danh mục cuộn ngang
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('Tất cả'),
                      selected: catalog.selectedCategoryId == null,
                      onSelected: (_) => catalog.selectCategory(null),
                    ),
                  ),
                  ...catalog.categories.map((cat) {
                    final isSelected =
                        catalog.selectedCategoryId == cat.categoryId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(
                          cat.productCount > 0
                              ? '${cat.categoryName} (${cat.productCount})'
                              : cat.categoryName,
                        ),
                        selected: isSelected,
                        onSelected: (_) =>
                            catalog.selectCategory(cat.categoryId),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lưới sản phẩm
            Expanded(
              child: Builder(
                builder: (context) {
                  if (catalog.isLoadingProducts && catalog.products.isEmpty) {
                    return const LoadingView(
                        message: 'Đang tải danh sách sản phẩm...');
                  }
                  if (catalog.productsError != null &&
                      catalog.products.isEmpty) {
                    return ErrorView(
                      message: catalog.productsError!,
                      onRetry: () => catalog.refreshAll(),
                    );
                  }
                  if (catalog.products.isEmpty) {
                    return EmptyView(
                      title: 'Không có sản phẩm nào',
                      message: 'Vui lòng chọn danh mục khác hoặc xóa bộ lọc.',
                      onAction: () {
                        catalog.clearSearch();
                        catalog.selectCategory(null);
                      },
                      actionLabel: 'Xóa bộ lọc',
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: catalog.products.length +
                        (catalog.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == catalog.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        );
                      }
                      final product = catalog.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () =>
                            context.push('/product/${product.productId}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
