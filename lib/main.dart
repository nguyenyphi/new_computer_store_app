import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/config/app_router.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/catalog_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/services/auth_service.dart';
import 'data/services/auth_storage.dart';
import 'data/services/cart_storage.dart';
import 'data/services/catalog_service.dart';
import 'data/services/order_service.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/chatbot_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Khởi tạo Base URL hiệu lực từ SharedPreferences hoặc --dart-define hoặc mặc định
  await AppConfig.initEffectiveBaseUrl();

  // 1. Khởi tạo tầng lưu trữ bảo mật Token (Keystore / SharedPreferences an toàn)
  final authStorage = AuthStorage();

  // Khởi tạo tầng lưu trữ giỏ hàng local bằng SharedPreferences
  final cartStorage = CartStorage();

  // Biến giữ tham chiếu AuthProvider để kích hoạt logout khi gặp lỗi 401
  late final AuthProvider authProvider;

  // 2. Khởi tạo ApiClient kết nối Backend ASP.NET Core
  final apiClient = ApiClient(
    authStorage: authStorage,
    onUnauthorized: () {
      authProvider.handleUnauthorized();
    },
  );

  // 3. Khởi tạo các Services và Repositories
  final authService = AuthService(apiClient: apiClient);
  final authRepository = AuthRepository(
    authService: authService,
    authStorage: authStorage,
  );

  final catalogService = CatalogService(apiClient: apiClient);
  final catalogRepository = CatalogRepository(catalogService: catalogService);

  final orderService = OrderService(apiClient: apiClient);
  final orderRepository = OrderRepository(orderService: orderService);

  // 4. Khởi tạo AuthProvider
  authProvider = AuthProvider(authRepository: authRepository);

  // Kiểm tra token lưu trong Keystore xem còn hợp lệ không trước khi hiển thị giao diện
  await authProvider.checkInitialAuth();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(
          value: apiClient,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
        Provider<CatalogRepository>.value(
          value: catalogRepository,
        ),
        ChangeNotifierProvider<CatalogProvider>(
          create: (ctx) => CatalogProvider(
            catalogRepository: catalogRepository,
          ),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(cartStorage: cartStorage),
        ),
        Provider<OrderRepository>.value(
          value: orderRepository,
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (ctx) => OrderProvider(orderRepository: orderRepository),
        ),
        ChangeNotifierProvider<ChatbotProvider>(
          create: (_) => ChatbotProvider(catalogRepository: catalogRepository),
        ),
      ],
      child: const ComputerStoreApp(),
    ),
  );
}

class ComputerStoreApp extends StatefulWidget {
  const ComputerStoreApp({super.key});

  @override
  State<ComputerStoreApp> createState() => _ComputerStoreAppState();
}

class _ComputerStoreAppState extends State<ComputerStoreApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.createRouter(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
    );
  }
}
