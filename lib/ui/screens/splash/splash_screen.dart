import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';

/// Màn hình Splash (Khởi động ứng dụng)
/// Hiển thị nhận diện thương hiệu, kiểm tra tính hợp lệ của token Keystore
/// và tải giỏ hàng cục bộ trước khi chuyển sang Trang chủ.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Khởi tạo dữ liệu hệ thống
  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // 1. Kiểm tra Token Keystore, nạp giỏ hàng, nạp trước danh mục và sản phẩm
    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final catalogProvider = context.read<CatalogProvider>();

    await Future.wait([
      authProvider.checkInitialAuth(),
      cartProvider.loadCart(),
      catalogProvider.loadCategories(),
      catalogProvider.loadProducts(),
    ]);

    // 2. Đảm bảo màn hình hiển thị tối thiểu 1.2 giây để người dùng cảm nhận thương hiệu mượt mà
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 1200) {
      await Future.delayed(
        Duration(milliseconds: 1200 - elapsed.inMilliseconds),
      );
    }

    if (!mounted) return;

    // 3. Điều hướng mượt mà sang Trang chủ
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF0A0E17),
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ]
                : const [
                    Color(0xFFF0F9FF),
                    Color(0xFFE0F2FE),
                    Color(0xFFBAE6FD),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo ứng dụng với hiệu ứng Scale & Fade
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.primary,
                        child: const Icon(
                          Icons.laptop_chromebook,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Tên ứng dụng tiếng Việt
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'CỬA HÀNG MÁY TÍNH',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thiết Bị Công Nghệ & Linh Kiện Chính Hãng',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Vòng xoay nạp dữ liệu nhẹ nhàng
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đang khởi động hệ thống...',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
