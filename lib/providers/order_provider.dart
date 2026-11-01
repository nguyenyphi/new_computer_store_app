import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_exception.dart';
import '../data/models/create_order_request_model.dart';
import '../data/models/order_model.dart';
import '../data/models/payment_qr_model.dart';
import '../data/repositories/order_repository.dart';

/// Provider quản lý nghiệp vụ Đặt hàng, Danh sách đơn hàng và Thanh toán QR
class OrderProvider extends ChangeNotifier {
  final OrderRepository orderRepository;

  // Trạng thái danh sách đơn hàng
  List<OrderModel> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Trạng thái chi tiết đơn hàng
  OrderModel? _currentOrder;
  bool _isLoadingDetail = false;
  String? _detailError;

  // Trạng thái thanh toán QR
  PaymentQrModel? _paymentQr;
  bool _isLoadingQr = false;
  String? _qrError;

  // Trạng thái gửi đơn hàng (Checkout)
  bool _isSubmitting = false;
  String? _checkoutError;

  // Timer tự động làm mới trạng thái đơn hàng khi đang mở màn hình QR (mỗi 10 giây)
  Timer? _qrPollingTimer;

  OrderProvider({required this.orderRepository});

  List<OrderModel> get orders => _orders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;

  OrderModel? get currentOrder => _currentOrder;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  PaymentQrModel? get paymentQr => _paymentQr;
  bool get isLoadingQr => _isLoadingQr;
  String? get qrError => _qrError;

  bool get isSubmitting => _isSubmitting;
  String? get checkoutError => _checkoutError;

  /// Đặt hàng mới: POST /api/orders
  /// Xử lý đặc biệt lỗi 409 CONCURRENCY_CONFLICT và chặn bấm 2 lần
  Future<OrderModel?> submitOrder(CreateOrderRequestModel request) async {
    if (_isSubmitting) return null; // Chặn bấm đặt hàng 2 lần

    _isSubmitting = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final createdOrder = await orderRepository.createOrder(request);
      _currentOrder = createdOrder;
      return createdOrder;
    } on ApiException catch (e) {
      // Bắt lỗi 409 hoặc mã CONCURRENCY_CONFLICT
      if (e.statusCode == 409 ||
          e.code == 'CONCURRENCY_CONFLICT' ||
          (e.detail?.contains('CONCURRENCY_CONFLICT') ?? false)) {
        _checkoutError =
            'Sản phẩm vừa thay đổi/hết hàng, vui lòng kiểm tra lại giỏ hàng.';
      } else {
        // Hiện đúng thông điệp từ máy chủ
        _checkoutError = e.message;
      }
      return null;
    } catch (e) {
      _checkoutError = 'Đã xảy ra lỗi khi tạo đơn hàng: $e';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Tải danh sách đơn hàng của người dùng: GET /api/orders
  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      _orders = await orderRepository.getOrders();
    } on ApiException catch (e) {
      _ordersError = e.message;
    } catch (e) {
      _ordersError = 'Không thể tải danh sách đơn hàng: $e';
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  /// Tải chi tiết đơn hàng: GET /api/orders/{id}
  Future<void> loadOrderDetail(int orderId) async {
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      _currentOrder = await orderRepository.getOrderDetails(orderId);
    } on ApiException catch (e) {
      _detailError = e.message;
    } catch (e) {
      _detailError = 'Không thể tải chi tiết đơn hàng: $e';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// Tải thông tin thanh toán QR: GET /api/orders/{id}/payment-qr
  Future<void> loadPaymentQr(int orderId) async {
    _isLoadingQr = true;
    _qrError = null;
    notifyListeners();

    try {
      _paymentQr = await orderRepository.getPaymentQr(orderId);
    } on ApiException catch (e) {
      _qrError = e.message;
    } catch (e) {
      _qrError = 'Không thể tải thông tin thanh toán QR: $e';
    } finally {
      _isLoadingQr = false;
      notifyListeners();
    }
  }

  /// Bắt đầu tự động kiểm tra trạng thái đơn hàng mỗi 10 giây trên màn hình QR
  void startQrPolling(int orderId, VoidCallback onPaidSuccess) {
    stopQrPolling();

    _qrPollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final order = await orderRepository.getOrderDetails(orderId);
        _currentOrder = order;

        // Nếu đơn hàng đã được cập nhật thanh toán thành công (Paid)
        if (order.isPaid || order.status != 'Pending') {
          timer.cancel();
          notifyListeners();
          onPaidSuccess();
        }
      } catch (_) {
        // Bỏ qua lỗi polling định kỳ
      }
    });
  }

  /// Dừng bộ đếm thời gian polling khi thoát màn hình
  void stopQrPolling() {
    _qrPollingTimer?.cancel();
    _qrPollingTimer = null;
  }

  @override
  void dispose() {
    stopQrPolling();
    super.dispose();
  }
}
