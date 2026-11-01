import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/server_config_dialog.dart';

/// Màn hình Tài khoản: Gọi GET /api/me hiển thị profile người dùng,
/// chuyển đổi Dark/Light mode và chức năng Đăng xuất.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().loadProfile();
    });
  }

  /// Xử lý Đăng xuất
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (authProvider.isLoading && user == null) {
      return const Scaffold(
        body: LoadingView(message: 'Đang tải thông tin tài khoản...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài Khoản'),
        actions: [
          // Nút chuyển đổi Dark Mode nhanh trên AppBar
          IconButton(
            tooltip: 'Chuyển chế độ Giao diện',
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
        onRefresh: () => authProvider.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 1. Thẻ thông tin cá nhân (Profile Card)
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
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar người dùng
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.15),
                    child: user != null && user.fullName.isNotEmpty
                        ? Text(
                            user.fullName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.primaryDark : AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.person_outline,
                            size: 36,
                            color: isDark ? AppColors.primaryDark : AppColors.primary,
                          ),
                  ),
                  const SizedBox(width: 16),

                  // Họ tên và Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user != null
                              ? user.fullName
                              : 'Khách hàng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user != null
                              ? user.email
                              : 'Chưa đăng nhập vào tài khoản',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Vai trò Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Vai trò: ${user != null ? (user.role == "Admin" ? "Quản trị viên" : "Khách hàng") : "Khách"}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Chi tiết thông tin
            Text(
              'Cài đặt & Tùy chọn',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  // Chế độ Giao diện Tối
                  SwitchListTile(
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark ? AppColors.primaryDark : AppColors.primary,
                    ),
                    title: const Text('Giao diện tối (Dark Mode)'),
                    subtitle: Text(
                      themeProvider.isDarkMode ? 'Đang bật' : 'Đang tắt',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (val) => themeProvider.toggleTheme(),
                  ),
                  const Divider(height: 1),

                  // Cài đặt máy chủ API (Server URL)
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Cài đặt máy chủ (Server URL)'),
                    subtitle: Text(
                      AppConfig.baseUrl,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () async {
                      await ServerConfigDialog.show(context);
                      if (mounted) setState(() {});
                    },
                  ),
                  const Divider(height: 1),

                  // Thông tin số điện thoại (nếu có)
                  if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Số điện thoại'),
                      subtitle: Text(user.phoneNumber!),
                    ),
                    const Divider(height: 1),
                  ],

                  // Trạng thái tài khoản
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Trạng thái tài khoản'),
                    subtitle: Text(
                      user != null
                          ? (user.isActive ? 'Đang hoạt động' : 'Đã khóa')
                          : 'Chưa đăng nhập',
                      style: TextStyle(
                        color: user?.isActive == true ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hỗ trợ & Dịch vụ khách hàng
            Text(
              'Hỗ trợ & Tiện ích',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  // Trợ lý AI Tư vấn máy tính
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.primaryDark : AppColors.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: isDark ? AppColors.primaryDark : AppColors.primary,
                      ),
                    ),
                    title: const Text(
                      'Trợ lý AI Tư Vấn Máy Tính',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Chat 24/7 gợi ý Laptop, Build PC, giải đáp kỹ thuật',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/chatbot'),
                  ),
                  const Divider(height: 1),

                  // Mã giảm giá
                  ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined, color: Colors.orange),
                    title: const Text('Kho mã giảm giá (Vouchers)'),
                    subtitle: const Text('Mã SINHVIEN10, HE2026, FREESHIP', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showVouchersDialog(context),
                  ),
                  const Divider(height: 1),

                  // Chính sách bảo hành
                  ListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.success),
                    title: const Text('Chính sách bảo hành & đổi trả'),
                    subtitle: const Text('1 đổi 1 trong 30 ngày, bảo hành 12 - 36 tháng', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWarrantyDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Nút Đăng xuất hoặc Đăng nhập
            if (authProvider.isAuthenticated)
              OutlinedButton.icon(
                onPressed: _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập / Đăng ký ngay'),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showVouchersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.confirmation_number_rounded, color: Colors.orange, size: 26),
                  SizedBox(width: 10),
                  Text(
                    'Mã Giảm Giá Khả Dụng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildVoucherTile('SINHVIEN10', 'Giảm 10% toàn bộ đơn hàng', 'Dành riêng cho sinh viên lập trình & CNTT'),
              const SizedBox(height: 10),
              _buildVoucherTile('HE2026', 'Giảm trực tiếp 500.000 VNĐ', 'Đơn hàng từ 15.000.000 VNĐ'),
              const SizedBox(height: 10),
              _buildVoucherTile('FREESHIP', 'Miễn phí vận chuyển toàn quốc', 'Áp dụng cho mọi giá trị đơn hàng'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherTile(String code, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.deepOrange,
                  ),
                ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 32),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép mã $code!')),
              );
            },
            child: const Text('Lưu mã', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showWarrantyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Chính Sách Bảo Hành'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Đổi mới trong 30 ngày:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Áp dụng nếu sản phẩm lỗi phần cứng từ nhà sản xuất (nguyên hộp và phụ kiện).\n'),
              Text(
                '2. Bảo hành chính hãng 12 - 36 tháng:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Tại tất cả trung tâm bảo hành ủy quyền của ASUS, Dell, Apple, HP, Acer, MSI...\n'),
              Text(
                '3. Dịch vụ độc quyền trọn đời:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Miễn phí cài đặt hệ điều hành và phần mềm đồ họa\n• Vệ sinh tra keo tản nhiệt miễn phí định kỳ\n• Hotline hỗ trợ kỹ thuật: 1900 6868'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
