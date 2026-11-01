import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../providers/cart_provider.dart';
import '../../widgets/empty_view.dart';

/// Màn hình Giỏ hàng (Cart Screen)
/// Lưu trữ Local bằng SharedPreferences, tự động làm mới giá/tồn kho từ GET /api/products/{id}
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Tự động làm mới giá & tồn kho từ máy chủ khi vào màn hình Giỏ hàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogRepo = context.read<CatalogRepository>();
      context.read<CartProvider>().refreshCartPrices(catalogRepo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          cart.items.isNotEmpty
              ? 'Giỏ Hàng (${cart.totalItemsCount})'
              : 'Giỏ Hàng',
        ),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              tooltip: 'Làm mới giá & tồn kho',
              icon: cart.isRefreshingPrices
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: cart.isRefreshingPrices
                  ? null
                  : () {
                      final catalogRepo = context.read<CatalogRepository>();
                      cart.refreshCartPrices(catalogRepo);
                    },
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? EmptyView(
              title: 'Giỏ hàng đang trống',
              message:
                  'Bạn chưa có sản phẩm nào trong giỏ hàng. Hãy dạo quanh cửa hàng để chọn sản phẩm ưng ý nhé!',
              icon: Icons.remove_shopping_cart_outlined,
              actionLabel: 'Khám phá sản phẩm ngay',
              onAction: () => context.go('/home'),
            )
          : RefreshIndicator(
              onRefresh: () async {
                final catalogRepo = context.read<CatalogRepository>();
                await cart.refreshCartPrices(catalogRepo);
              },
              child: Column(
                children: [
                  // Cảnh báo nếu giá bị thay đổi so với lần trước
                  if (cart.hasPriceChangedNotice)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: AppColors.warning.withValues(alpha: 0.15),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.warning, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Giá một số sản phẩm đã được cập nhật theo giá mới nhất từ hệ thống.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Danh sách sản phẩm trong giỏ
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _buildCartItemCard(context, cart, item, isDark);
                      },
                    ),
                  ),

                  // Thanh thanh toán ở dưới cùng (Checkout Bar)
                  _buildBottomCheckoutBar(context, cart, isDark),
                ],
              ),
            ),
    );
  }

  /// Thẻ sản phẩm trong giỏ hàng
  Widget _buildCartItemCard(
    BuildContext context,
    CartProvider cart,
    dynamic item,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sản phẩm
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 80,
              height: 80,
              color: isDark ? const Color(0xFF161B22) : Colors.grey.shade100,
              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        Icons.computer,
                        size: 36,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(Icons.devices, size: 36, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin sản phẩm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên sản phẩm
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Biến thể màu sắc nếu có
                if (item.colorName != null && item.colorName!.isNotEmpty)
                  Text(
                    'Màu: ${item.colorName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),

                const SizedBox(height: 6),

                // Giá và Cảnh báo thay đổi giá
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.format(item.currentPrice),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    if (item.hasPriceChanged) ...[
                      const SizedBox(width: 6),
                      Text(
                        CurrencyFormatter.format(item.displayPrice),
                        style: TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),

                // Cảnh báo hết hàng
                if (item.isOutOfStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Sản phẩm đã hết hàng',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Bộ tăng giảm số lượng và nút xóa
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bộ tăng giảm
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => cart.updateQuantity(
                                item.productId, item.colorId, -1),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.remove, size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: item.isOutOfStock ||
                                    item.quantity >= item.maxStock
                                ? null
                                : () => cart.updateQuantity(
                                    item.productId, item.colorId, 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: item.isOutOfStock ||
                                        item.quantity >= item.maxStock
                                    ? Colors.grey
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Nút Xóa
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 20),
                      onPressed: () =>
                          cart.removeFromCart(item.productId, item.colorId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thanh đặt hàng ở dưới cùng
  Widget _buildBottomCheckoutBar(
    BuildContext context,
    CartProvider cart,
    bool isDark,
  ) {
    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng tạm tính:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(cart.totalAmount),
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
            ElevatedButton(
              onPressed:
                  (cart.items.isEmpty || cart.totalAmount <= 0 || _isNavigating)
                      ? null
                      : () async {
                          setState(() => _isNavigating = true);
                          await context.push('/checkout');
                          if (mounted) {
                            setState(() => _isNavigating = false);
                          }
                        },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Tiến hành đặt hàng'),
            ),
          ],
        ),
      ),
    );
  }
}
