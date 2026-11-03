import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/order_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

/// Màn hình Thanh toán qua mã VietQR
/// Tự động làm mới (polling) trạng thái đơn hàng mỗi 10 giây theo yêu cầu đề bài.
class PaymentQrScreen extends StatefulWidget {
  final int orderId;

  const PaymentQrScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();

      // 1. Tải thông tin QR thanh toán: GET /api/orders/{id}/payment-qr
      orderProvider.loadPaymentQr(widget.orderId);

      // 2. Khởi động Timer polling mỗi 10 giây kiểm tra trạng thái thanh toán đơn
      orderProvider.startQrPolling(widget.orderId, () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận thanh toán thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Chuyển sang màn hình xem chi tiết đơn hàng
        context.go('/orders/${widget.orderId}');
      });
    });
  }

  @override
  void dispose() {
    // Hủy bỏ Timer polling ngay khi người dùng rời khỏi màn hình
    context.read<OrderProvider>().stopQrPolling();
    super.dispose();
  }

  /// Hàm sao chép nhanh vào Clipboard kèm thông báo
  void _copyToClipboard(String label, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final qrData = orderProvider.paymentQr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (orderProvider.isLoadingQr && qrData == null) {
      return const Scaffold(
        body: LoadingView(message: 'Đang tạo mã thanh toán VietQR...'),
      );
    }

    if (orderProvider.qrError != null && qrData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh Toán QR')),
        body: ErrorView(
          message: orderProvider.qrError!,
          onRetry: () => orderProvider.loadPaymentQr(widget.orderId),
        ),
      );
    }

    if (qrData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thanh Toán QR')),
        body: const Center(child: Text('Không tìm thấy thông tin thanh toán')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/orders/${widget.orderId}');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thanh Toán Đơn #${widget.orderId}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Xem đơn hàng',
            onPressed: () => context.go('/orders/${widget.orderId}'),
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Thẻ chứa mã QR và hướng dẫn chuyển khoản
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Quét mã VietQR để thanh toán',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mở ứng dụng Ngân hàng hoặc MoMo để quét',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ảnh mã QR
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CachedNetworkImage(
                        imageUrl: qrData.qrImageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, _) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        errorWidget: (_, _, _) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Không tải được ảnh QR',
                                style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Số tiền cần chuyển
                  Text(
                    CurrencyFormatter.format(qrData.amount),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Trạng thái kiểm tra thanh toán
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.info,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tự động kiểm tra trạng thái mỗi 10 giây...',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin chuyển khoản chi tiết kèm nút Sao chép
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Ngân hàng
                    _buildInfoRow(
                      context,
                      'Ngân hàng',
                      qrData.bankName ?? 'MoMo',
                      null,
                    ),
                    const Divider(height: 18),

                    // Chủ tài khoản
                    _buildInfoRow(
                      context,
                      'Chủ tài khoản',
                      qrData.accountName ?? 'Võ Anh Tuấn',
                      null,
                    ),
                    const Divider(height: 18),

                    // Số tài khoản
                    _buildInfoRow(
                      context,
                      'Số tài khoản',
                      qrData.accountNumber ?? '0845644491',
                      () => _copyToClipboard(
                          'Số tài khoản', qrData.accountNumber ?? '0845644491'),
                    ),
                    const Divider(height: 18),

                    // Nội dung chuyển khoản
                    _buildInfoRow(
                      context,
                      'Nội dung CK',
                      qrData.transferContent,
                      () => _copyToClipboard(
                          'Nội dung chuyển khoản', qrData.transferContent),
                      highlight: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút hoàn tất / Tôi đã chuyển khoản
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/orders/${widget.orderId}'),
                child: const Text('Tôi đã chuyển khoản xong'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Quay lại trang chủ'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    VoidCallback? onCopy, {
    bool highlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: highlight
                        ? (isDark ? AppColors.primaryDark : AppColors.primary)
                        : null,
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Sao chép',
                  onPressed: onCopy,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
