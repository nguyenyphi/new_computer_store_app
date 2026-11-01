import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Hộp thoại cấu hình và đổi địa chỉ máy chủ API ngay trong app
class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  /// Hàm tiện ích mở Dialog cấu hình máy chủ
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  bool _isTesting = false;
  bool _isSaving = false;
  String? _testMessage;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: AppConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Kiểm tra kết nối tới máy chủ được nhập
  Future<void> _handleTestConnection() async {
    final validationError = AppConfig.validateUrl(_controller.text);
    if (validationError != null) {
      setState(() {
        _testSuccess = false;
        _testMessage = validationError;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = null;
    });

    final targetUrl = AppConfig.normalizeUrl(_controller.text);
    final result = await ApiClient.testConnection(targetUrl);

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testSuccess = result.success;
      _testMessage = result.message;
    });
  }

  /// Lưu địa chỉ mới vào SharedPreferences, cập nhật Dio, xóa token và chuyển về Login
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newUrl = AppConfig.normalizeUrl(_controller.text);
    final authProvider = context.read<AuthProvider>();
    final apiClient = context.read<ApiClient>();

    // 1. Lưu vào SharedPreferences
    await AppConfig.saveCustomBaseUrl(newUrl);

    // 2. Cập nhật ngay Base URL cho Dio
    apiClient.updateBaseUrl(newUrl);

    // 3. Xóa token và phiên đăng nhập cũ
    await authProvider.logout();

    if (!mounted) return;

    setState(() => _isSaving = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật máy chủ: $newUrl\nĐã chuyển về màn Đăng nhập.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );

    context.go('/login');
  }

  /// Đặt lại địa chỉ mặc định
  Future<void> _handleReset() async {
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final apiClient = context.read<ApiClient>();

    // 1. Xóa cấu hình tùy chỉnh
    await AppConfig.resetDefaultBaseUrl();

    // 2. Cập nhật Dio với URL mặc định
    apiClient.updateBaseUrl(AppConfig.baseUrl);

    // 3. Xóa token cũ
    await authProvider.logout();

    if (!mounted) return;

    _controller.text = AppConfig.baseUrl;

    setState(() {
      _isSaving = false;
      _testMessage = null;
      _testSuccess = null;
    });

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đặt lại máy chủ mặc định: ${AppConfig.baseUrl}\nĐã chuyển về màn Đăng nhập.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.dns_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Cài Đặt Máy Chủ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thông tin giải thích thứ tự ưu tiên
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Thứ tự ưu tiên máy chủ:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '1. Đã lưu trong app (cao nhất)\n'
                        '2. Biến --dart-define=BASE_URL=...\n'
                        '3. Mặc định (${AppConfig.defaultBaseUrl})',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ô nhập URL máy chủ
                TextFormField(
                  controller: _controller,
                  enabled: !_isTesting && !_isSaving,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ máy chủ (Base URL)',
                    hintText: 'https://oldorangeapple30.conveyor.cloud/',
                    prefixIcon: const Icon(Icons.link_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Xóa nội dung',
                      onPressed: () => _controller.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: AppConfig.validateUrl,
                ),
                const SizedBox(height: 12),

                // Nút kiểm tra kết nối
                OutlinedButton.icon(
                  onPressed: (_isTesting || _isSaving) ? null : _handleTestConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering, size: 18),
                  label: Text(_isTesting ? 'Đang kiểm tra kết nối...' : 'Kiểm tra kết nối (GET /api/categories)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Kết quả kiểm tra kết nối
                if (_testMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_testSuccess == true ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testSuccess == true ? AppColors.success : AppColors.error,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testSuccess == true
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: _testSuccess == true ? AppColors.success : AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _testSuccess == true ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        // Nút Đặt lại mặc định
        TextButton.icon(
          onPressed: (_isTesting || _isSaving) ? null : _handleReset,
          icon: const Icon(Icons.restore, size: 16),
          label: const Text('Đặt lại mặc định'),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
        ),
        const Spacer(),
        // Nút Hủy / Đóng
        TextButton(
          onPressed: (_isTesting || _isSaving) ? null : () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        // Nút Lưu
        ElevatedButton.icon(
          onPressed: (_isTesting || _isSaving) ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save_rounded, size: 16),
          label: const Text('Lưu máy chủ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
