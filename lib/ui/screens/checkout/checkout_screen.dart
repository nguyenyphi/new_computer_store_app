import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validator.dart';
import '../../../data/models/create_order_request_model.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/order_provider.dart';

/// Màn hình Thanh toán (Checkout Screen)
/// Bắt buộc đăng nhập, kiểm tra concurrency 409, chặn bấm 2 lần và hỗ trợ COD/QR.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final TextEditingController _voucherController = TextEditingController();

  String _selectedPaymentMethod = 'QR'; // "QR" hoặc "COD" theo docs/API.md
  double _discountAmount = 0.0;
  String? _appliedVoucherCode;
  String? _voucherMessage;

  void _applyVoucher(double subtotal) {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _discountAmount = 0.0;
        _appliedVoucherCode = null;
        _voucherMessage = null;
      });
      return;
    }

    if (code == 'SINHVIEN10') {
      setState(() {
        _discountAmount = subtotal * 0.10;
        _appliedVoucherCode = code;
        _voucherMessage = 'Áp dụng thành công: Giảm 10% sinh viên!';
      });
    } else if (code == 'HE2026') {
      if (subtotal >= 15000000) {
        setState(() {
          _discountAmount = 500000.0;
          _appliedVoucherCode = code;
          _voucherMessage = 'Áp dụng thành công: Giảm 500.000 VNĐ!';
        });
      } else {
        setState(() {
          _discountAmount = 0.0;
          _appliedVoucherCode = null;
          _voucherMessage = 'Đơn hàng chưa đạt mức tối thiểu 15.000.000 VNĐ';
        });
      }
    } else if (code == 'FREESHIP') {
      setState(() {
        _discountAmount = 30000.0;
        _appliedVoucherCode = code;
        _voucherMessage = 'Áp dụng thành công: Miễn phí vận chuyển!';
      });
    } else {
      setState(() {
        _discountAmount = 0.0;
        _appliedVoucherCode = null;
        _voucherMessage = 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController();

    // Làm mới giá & tồn kho một lần nữa trước khi xác nhận đặt hàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authProvider.isAuthenticated) {
        // Chưa đăng nhập -> Chuyển sang Login kèm thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đăng nhập để tiến hành đặt hàng.'),
            backgroundColor: AppColors.warning,
          ),
        );
        context.push('/login');
      } else {
        final catalogRepo = context.read<CatalogRepository>();
        context.read<CartProvider>().refreshCartPrices(catalogRepo);
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  /// Xử lý gửi đơn hàng
  Future<void> _handlePlaceOrder() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      context.push('/login');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartProvider>();
    final orderProvider = context.read<OrderProvider>();

    // Lọc ra các sản phẩm còn hàng
    final validItems = cart.items.where((i) => !i.isOutOfStock).toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giỏ hàng không có sản phẩm nào hợp lệ để đặt.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final orderRequest = CreateOrderRequestModel(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      voucherCode: _voucherController.text.trim(),
      items: validItems
          .map(
            (i) => CreateOrderItemRequest(
              productId: i.productId,
              colorId: i.colorId,
              quantity: i.quantity,
            ),
          )
          .toList(),
    );

    // Gửi yêu cầu đặt hàng tới Backend (POST /api/orders)
    final createdOrder = await orderProvider.submitOrder(orderRequest);

    if (!mounted) return;

    if (createdOrder != null) {
      // Đặt hàng thành công: Xóa giỏ hàng local
      await cart.clearCart();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt hàng thành công!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Chuyển hướng theo phương thức thanh toán
      if (_selectedPaymentMethod == 'QR') {
        context.go('/orders/${createdOrder.orderId}/payment-qr');
      } else {
        context.go('/order-success/${createdOrder.orderId}');
      }
    } else {
      // Hiển thị lỗi từ máy chủ hoặc lỗi 409 CONCURRENCY_CONFLICT
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.checkoutError ??
                'Đặt hàng thất bại. Vui lòng kiểm tra lại giỏ hàng.',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh Toán Đơn Hàng'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thông tin giao hàng
              Text(
                'Thông tin nhận hàng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Họ và tên người nhận
                      TextFormField(
                        controller: _fullNameController,
                        validator: FormValidators.validateFullName,
                        decoration: const InputDecoration(
                          labelText: 'Họ và tên người nhận',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Số điện thoại
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại nhận hàng';
                          }
                          if (val.trim().length < 10) {
                            return 'Số điện thoại không hợp lệ (tối thiểu 10 số)';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại liên hệ',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Địa chỉ giao hàng
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập địa chỉ nhận hàng chi tiết';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ nhận hàng chi tiết',
                          hintText: 'Số nhà, tên đường, phường/xã, quận/huyện...',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. Phương thức thanh toán
              Text(
                'Phương thức thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      onTap: () => setState(() => _selectedPaymentMethod = 'QR'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedPaymentMethod == 'QR'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: _selectedPaymentMethod == 'QR'
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.qr_code_scanner,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Chuyển khoản mã VietQR',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Quét mã QR qua app ngân hàng hoặc MoMo (Khuyên dùng)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    InkWell(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      onTap: () => setState(() => _selectedPaymentMethod = 'COD'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedPaymentMethod == 'COD'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: _selectedPaymentMethod == 'COD'
                                  ? AppColors.primary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping_outlined,
                                        color: AppColors.secondary,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Thanh toán khi nhận hàng (COD)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Thanh toán tiền mặt cho nhân viên giao hàng',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Mã giảm giá Voucher
              Text(
                'Mã ưu đãi (Voucher)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _voucherController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: 'Nhập mã: SINHVIEN10, HE2026, FREESHIP',
                                prefixIcon: Icon(Icons.confirmation_number_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _applyVoucher(cart.totalAmount),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Áp dụng'),
                          ),
                        ],
                      ),
                      if (_voucherMessage != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _discountAmount > 0
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              size: 16,
                              color: _discountAmount > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _voucherMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _discountAmount > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Tóm tắt đơn hàng
              Text(
                'Sản phẩm trong đơn (${cart.items.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ...cart.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Text(
                                  '${item.productName}${item.colorName != null ? ' (${item.colorName})' : ''} x${item.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  CurrencyFormatter.format(item.totalPrice),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tạm tính:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            CurrencyFormatter.format(cart.totalAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giảm giá (${_appliedVoucherCode ?? "Voucher"}):',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '- ${CurrencyFormatter.format(_discountAmount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng thanh toán:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              (cart.totalAmount - _discountAmount) > 0
                                  ? (cart.totalAmount - _discountAmount)
                                  : 0.0,
                            ),
                            style: TextStyle(
                              fontSize: 20,
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

              // Nút Đặt hàng ngay (Chặn bấm 2 lần khi đang gửi)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: orderProvider.isSubmitting || cart.items.isEmpty
                      ? null
                      : _handlePlaceOrder,
                  child: orderProvider.isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Xác nhận đặt hàng',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
