import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_color_model.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/product_detail_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Màn hình Chi tiết sản phẩm với Gallery ảnh PageView, chọn màu sắc,
/// bảng thông số kỹ thuật ExpansionTile và chọn số lượng không vượt tồn kho.
class ProductDetailScreen extends StatelessWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProductDetailProvider(
        catalogRepository: ctx.read<CatalogRepository>(),
      )..loadProductDetail(productId),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView();

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    final detailProvider = context.watch<ProductDetailProvider>();
    final product = detailProvider.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (detailProvider.isLoading && product == null) {
      return const Scaffold(
        body: LoadingView(message: 'Đang tải thông tin chi tiết sản phẩm...'),
      );
    }

    if (detailProvider.errorMessage != null && product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: detailProvider.errorMessage!,
          onRetry: () {
            // Lấy lại ID từ route hiện tại để thử lại
            final currentId = detailProvider.product?.productId;
            if (currentId != null) {
              detailProvider.loadProductDetail(currentId);
            }
          },
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy sản phẩm')),
      );
    }

    final images = product.allImages;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép liên kết sản phẩm!')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => detailProvider.loadProductDetail(product.productId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Gallery ảnh vuốt ngang (PageView) + Dots Indicator
              _buildImageGallery(context, detailProvider, images, isDark),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên sản phẩm
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Giá bán & Giảm giá
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.format(product.finalPrice),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.primaryDark
                                : AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 12),
                          Text(
                            CurrencyFormatter.format(product.price),
                            style: TextStyle(
                              fontSize: 15,
                              decoration: TextDecoration.lineThrough,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.discountBadge,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${product.discountPercent.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Trạng thái tồn kho
                    Row(
                      children: [
                        Icon(
                          product.isOutOfStock
                              ? Icons.cancel_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                          color: product.isOutOfStock
                              ? AppColors.error
                              : AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.isOutOfStock
                              ? 'Hết hàng'
                              : 'Còn hàng (Tồn kho: ${product.quantity})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: product.isOutOfStock
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),

                    // 2. Chọn biến thể màu sắc (Color Selector)
                    if (product.productColors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Màu sắc:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: product.productColors.map((color) {
                          final isSelected =
                              detailProvider.selectedColor?.id == color.id;
                          return _buildColorChip(
                            context,
                            color,
                            isSelected,
                            isDark,
                            () => detailProvider.selectColor(color),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],

                    // 3. Chọn số lượng mua (Không vượt quá tồn kho)
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số lượng:',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: product.isOutOfStock
                                    ? null
                                    : () => detailProvider.decreaseQuantity(),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '${detailProvider.selectedQuantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: product.isOutOfStock
                                    ? null
                                    : () => detailProvider.increaseQuantity(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),

                    // 4. Mô tả chi tiết sản phẩm
                    if (product.description != null &&
                        product.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Mô tả sản phẩm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                    ],

                    // 5. Bảng thông số kỹ thuật theo nhóm (ExpansionTile)
                    if (product.specGroups.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Thông số kỹ thuật',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...product.specGroups.map(
                        (group) => _buildSpecGroup(group, isDark),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 80), // Chừa khoảng trống cho Bottom Bar
            ],
          ),
        ),
      ),

      // 6. Nút "Thêm vào giỏ" ở Bottom Navigation Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Tổng tiền tạm tính
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tạm tính:',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(
                        product.finalPrice * detailProvider.selectedQuantity,
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Nút Thêm vào giỏ hàng
              ElevatedButton.icon(
                onPressed: (product.isOutOfStock || _isAdding)
                    ? null
                    : () async {
                        setState(() => _isAdding = true);
                        try {
                          final cartProvider = context.read<CartProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final success = await cartProvider.addToCart(
                            product: product,
                            color: detailProvider.selectedColor,
                            quantity: detailProvider.selectedQuantity,
                          );

                          if (!context.mounted) return;

                          if (success) {
                            final colorText = detailProvider.selectedColor != null
                                ? ' (${detailProvider.selectedColor!.colorName})'
                                : '';
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm "${product.productName}$colorText" (x${detailProvider.selectedQuantity}) vào giỏ hàng!',
                                ),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'Xem giỏ',
                                  textColor: Colors.white,
                                  onPressed: () => context.go('/cart'),
                                ),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Không thể thêm do sản phẩm đã hết hàng.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isAdding = false);
                        }
                      },
                icon: _isAdding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(
                  product.isOutOfStock
                      ? 'Hết hàng'
                      : (_isAdding ? 'Đang thêm...' : 'Thêm vào giỏ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gallery ảnh vuốt ngang sử dụng PageView
  Widget _buildImageGallery(
    BuildContext context,
    ProductDetailProvider provider,
    List<String> images,
    bool isDark,
  ) {
    if (images.isEmpty) {
      return Container(
        height: 280,
        color: isDark ? const Color(0xFF161B22) : Colors.grey.shade100,
        alignment: Alignment.center,
        child: Icon(
          Icons.devices_other,
          size: 72,
          color: Colors.grey.shade500,
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (idx) => provider.setImageIndex(idx),
            itemBuilder: (context, index) {
              final url = images[index];
              return Container(
                color: isDark ? const Color(0xFF161B22) : Colors.grey.shade100,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                ),
              );
            },
          ),

          // Dots Indicator chỉ số trang ảnh
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (idx) {
                  final isCurrent = idx == provider.currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? (isDark ? AppColors.primaryDark : AppColors.primary)
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// Chip chọn màu sắc sản phẩm
  Widget _buildColorChip(
    BuildContext context,
    ProductColorModel color,
    bool isSelected,
    bool isDark,
    VoidCallback onTap,
  ) {
    Color? parsedColor;
    try {
      final hex = color.colorCode.replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('0xFF$hex'));
      }
    } catch (_) {}

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.primaryDark : AppColors.primary)
                : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (parsedColor != null) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: parsedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              color.colorName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (color.quantity > 0) ...[
              const SizedBox(width: 4),
              Text(
                '(${color.quantity})',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Khối nhóm thông số kỹ thuật (ExpansionTile)
  Widget _buildSpecGroup(dynamic group, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            group.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: List.generate(group.specKeys.length, (index) {
                  final spec = group.specKeys[index];
                  final isEven = index % 2 == 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isEven
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade50)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            spec.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 6,
                          child: Text(
                            spec.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
