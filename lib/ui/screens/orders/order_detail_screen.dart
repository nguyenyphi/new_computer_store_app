import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Màn hình Chi tiết Đơn hàng (GET /api/orders/{id})
/// Hiển thị sản phẩm đã mua, tổng tiền, trạng thái, và nút "Xem QR thanh toán" nếu chưa thanh toán.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentOrder;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (orderProvider.isLoadingDetail && order == null) {
      return const Scaffold(
        body: LoadingView(message: 'Đang tải chi tiết đơn hàng...'),
      );
    }

    if (orderProvider.detailError != null && order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Đơn Hàng')),
        body: ErrorView(
          message: orderProvider.detailError!,
          onRetry: () => orderProvider.loadOrderDetail(widget.orderId),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Đơn Hàng')),
        body: const Center(child: Text('Không tìm thấy đơn hàng này.')),
      );
    }

    final dateStr =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(order.orderDate.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text('Đơn Hàng #DH${order.orderId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/orders');
            }
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderProvider.loadOrderDetail(widget.orderId),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thẻ trạng thái đơn hàng
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trạng thái đơn hàng',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      _buildStatusChip(order.status),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Banner / Nút "Xem QR thanh toán" nếu chưa thanh toán và dùng phương thức QR
              if (order.isPendingPayment) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pending_actions,
                              color: AppColors.warning),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Đơn hàng đang chờ thanh toán qua mã QR VietQR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/orders/${order.orderId}/payment-qr');
                          },
                          icon: const Icon(Icons.qr_code, size: 20),
                          label: const Text('Xem QR thanh toán'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Thông tin người nhận hàng
              Text(
                'Địa chỉ nhận hàng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            order.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${order.phone})',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.address,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Danh sách sản phẩm đã mua
              Text(
                'Sản phẩm đã mua (${order.orderDetails.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: order.orderDetails.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = order.orderDetails[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: isDark
                                ? const Color(0xFF161B22)
                                : Colors.grey.shade100,
                            child: item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => const Icon(
                                        Icons.computer,
                                        size: 28),
                                  )
                                : const Icon(Icons.devices, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item.colorName != null &&
                                  item.colorName!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Màu: ${item.colorName}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'x${item.quantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                        item.finalPrice * item.quantity),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 5. Thông tin thanh toán & Tổng tiền
              Text(
                'Chi tiết thanh toán',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        'Phương thức',
                        order.paymentMethod == 'QR'
                            ? 'Chuyển khoản VietQR'
                            : 'Thanh toán tiền mặt COD',
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Trạng thái thanh toán',
                        order.paymentStatus == 'Paid'
                            ? 'Đã thanh toán'
                            : 'Chờ thanh toán',
                        isDark,
                        color: order.paymentStatus == 'Paid'
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng thành tiền',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(order.totalPrice),
                            style: TextStyle(
                              fontSize: 18,
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
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

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
