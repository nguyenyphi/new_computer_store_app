import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Màn hình Danh sách Đơn hàng (Orders Screen)
/// Gọi GET /api/orders, hỗ trợ pull-to-refresh và gắn chip màu theo trạng thái
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<OrderProvider>().loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Chưa đăng nhập -> Yêu cầu đăng nhập để xem đơn hàng
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn Hàng')),
        body: EmptyView(
          title: 'Bạn chưa đăng nhập',
          message: 'Vui lòng đăng nhập để xem lịch sử mua sắm và quản lý đơn hàng của bạn.',
          icon: Icons.lock_outline,
          actionLabel: 'Đăng nhập ngay',
          onAction: () => context.push('/login'),
        ),
      );
    }

    if (orderProvider.isLoadingOrders && orderProvider.orders.isEmpty) {
      return const Scaffold(
        body: LoadingView(message: 'Đang tải danh sách đơn hàng...'),
      );
    }

    if (orderProvider.ordersError != null && orderProvider.orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Đơn Hàng')),
        body: ErrorView(
          message: orderProvider.ordersError!,
          onRetry: () => orderProvider.loadOrders(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Sử Đơn Hàng'),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.loadOrders(),
        child: orderProvider.orders.isEmpty
            ? EmptyView(
                title: 'Chưa có đơn hàng nào',
                message: 'Bạn chưa thực hiện đơn đặt hàng nào trong hệ thống.',
                icon: Icons.receipt_long_outlined,
                actionLabel: 'Mua sắm ngay',
                onAction: () => context.go('/home'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return _buildOrderCard(context, order, isDark);
                },
              ),
      ),
    );
  }

  /// Card hiển thị thông tin từng đơn hàng
  Widget _buildOrderCard(BuildContext context, OrderModel order, bool isDark) {
    final dateStr =
        DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate.toLocal());

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/orders/${order.orderId}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng trên: Mã đơn & Chip trạng thái màu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primary)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_outlined,
                          size: 18,
                          color:
                              isDark ? AppColors.primaryDark : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#DH${order.orderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 10),

              // Ngày đặt
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Phương thức thanh toán
              Row(
                children: [
                  Icon(
                    order.paymentMethod == 'QR'
                        ? Icons.qr_code_2
                        : Icons.local_shipping_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    order.paymentMethod == 'QR'
                        ? 'Chuyển khoản VietQR (${order.paymentStatus == "Paid" ? "Đã thanh toán" : "Chờ thanh toán"})'
                        : 'Thanh toán tiền mặt COD',
                    style: TextStyle(
                      fontSize: 12,
                      color: order.paymentStatus == "Paid"
                          ? AppColors.success
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                      fontWeight: order.paymentStatus == "Paid"
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Hàng dưới: Số lượng và Tổng tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.itemCount} sản phẩm',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Tổng: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(order.totalPrice),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.primaryDark
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip màu trạng thái đơn hàng theo yêu cầu
  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'Chờ xác nhận';
        break;
      case 'processing':
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
        label = 'Đang xử lý';
        break;
      case 'shipped':
        bg = const Color(0xFF7B2CBF).withValues(alpha: 0.15);
        fg = const Color(0xFF7B2CBF);
        label = 'Đang giao';
        break;
      case 'delivered':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        label = 'Đã giao hàng';
        break;
      case 'cancelled':
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        label = 'Đã hủy';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
