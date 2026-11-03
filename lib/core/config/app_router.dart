import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../ui/screens/account/account_screen.dart';
import '../../ui/screens/auth/forgot_password_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/otp_verification_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/auth/reset_password_screen.dart';
import '../../ui/screens/cart/cart_screen.dart';
import '../../ui/screens/catalog/catalog_screen.dart';
import '../../ui/screens/chatbot/chatbot_screen.dart';
import '../../ui/screens/checkout/checkout_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/orders/order_detail_screen.dart';
import '../../ui/screens/orders/order_success_screen.dart';
import '../../ui/screens/orders/orders_screen.dart';
import '../../ui/screens/orders/payment_qr_screen.dart';
import '../../ui/screens/product_detail/product_detail_screen.dart';
import '../../ui/screens/shell/main_shell_screen.dart';
import '../../ui/screens/splash/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Bộ cấu hình điều hướng GoRouter tập trung
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final location = state.uri.path;

        // Cho phép Splash Screen chạy tự nhiên
        if (location == '/splash') return null;

        // Chưa khởi tạo xong trạng thái ban đầu thì giữ nguyên
        if (!authProvider.isInitialized) return null;

        final isAuthenticated = authProvider.isAuthenticated;

        final isAuthRoute = location == '/login' ||
            location == '/register' ||
            location == '/otp-verify' ||
            location == '/forgot-password' ||
            location == '/reset-password';

        // 1. Đã đăng nhập mà cố vào màn auth -> Chuyển về trang đích (nếu có) hoặc trang chủ
        if (isAuthenticated && isAuthRoute) {
          final from = state.uri.queryParameters['from'];
          if (from != null && from.isNotEmpty) {
            return from;
          }
          return '/home';
        }

        // 2. Các màn hình yêu cầu bắt buộc đăng nhập
        final isProtectedRoute = location == '/checkout' ||
            (location.startsWith('/orders/') && location != '/orders');

        if (!isAuthenticated && isProtectedRoute) {
          return '/login?from=$location';
        }

        return null;
      },
      routes: [
        // ================= SPLASH ROUTE =================
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // ================= AUTH ROUTES =================
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final from = state.uri.queryParameters['from'];
            return LoginScreen(from: from);
          },
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/otp-verify',
          builder: (context, state) {
            final email = (state.extra as String?) ?? '';
            return OtpVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final email = (state.extra as String?) ?? '';
            return ResetPasswordScreen(email: email);
          },
        ),

        // ================= CHI TIẾT SẢN PHẨM =================
        GoRoute(
          path: '/product/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '0';
            final productId = int.tryParse(idStr) ?? 0;
            return ProductDetailScreen(productId: productId);
          },
        ),

        // ================= CHECKOUT & THANH TOÁN =================
        GoRoute(
          path: '/checkout',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/orders/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '0';
            final orderId = int.tryParse(idStr) ?? 0;
            return OrderDetailScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/orders/:id/payment-qr',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '0';
            final orderId = int.tryParse(idStr) ?? 0;
            return PaymentQrScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/order-success/:id',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final idStr = state.pathParameters['id'] ?? '0';
            final orderId = int.tryParse(idStr) ?? 0;
            return OrderSuccessScreen(orderId: orderId);
          },
        ),

        // ================= TRỢ LÝ AI CHATBOT =================
        GoRoute(
          path: '/chatbot',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ChatbotScreen(),
        ),

        // ================= BOTTOM NAVIGATION SHELL ROUTE =================
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShellScreen(navigationShell: navigationShell);
          },
          branches: [
            // Tab 1: Trang chủ
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),

            // Tab 2: Danh mục
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/catalog',
                  builder: (context, state) => const CatalogScreen(),
                ),
              ],
            ),

            // Tab 3: Giỏ hàng (Local Cart)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  builder: (context, state) => const CartScreen(),
                ),
              ],
            ),

            // Tab 4: Đơn hàng (Order History)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/orders',
                  builder: (context, state) => const OrdersScreen(),
                ),
              ],
            ),

            // Tab 5: Tài khoản
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/account',
                  builder: (context, state) => const AccountScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
