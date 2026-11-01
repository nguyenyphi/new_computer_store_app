import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Màn hình Thông báo Đặt hàng thành công (dành cho COD)
class OrderSuccessScreen extends StatelessWidget {
  final int orderId;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon thành công
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Đặt Hàng Thành Công!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Mã đơn hàng của bạn: #DH$orderId',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Cảm ơn bạn đã mua hàng tại Computer Store. Nhân viên tư vấn sẽ liên hệ để xác nhận và giao hàng sớm nhất.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                // Nút Xem chi tiết đơn hàng
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.go('/orders/$orderId'),
                    child: const Text('Xem chi tiết đơn hàng'),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Tiếp tục mua sắm
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Tiếp tục mua sắm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
