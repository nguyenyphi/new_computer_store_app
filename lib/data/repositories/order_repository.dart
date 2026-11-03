import '../models/create_order_request_model.dart';
import '../models/order_model.dart';
import '../models/payment_qr_model.dart';
import '../services/order_service.dart';

/// Repository quản lý nghiệp vụ Đơn hàng và Thanh toán.
/// Kết nối trực tiếp tới API Backend, không tạo đơn hàng ảo phía client.
class OrderRepository {
  final OrderService orderService;

  OrderRepository({required this.orderService});

  /// Tạo đơn hàng mới: POST /api/orders
  Future<OrderModel> createOrder(CreateOrderRequestModel request) {
    return orderService.createOrder(request);
  }

  /// Lấy danh sách lịch sử đơn hàng: GET /api/orders
  Future<List<OrderModel>> getOrders() {
    return orderService.getOrders();
  }

  /// Lấy chi tiết đơn hàng: GET /api/orders/{id}
  Future<OrderModel> getOrderDetails(int orderId) {
    return orderService.getOrderDetails(orderId);
  }

  /// Lấy mã QR thanh toán: GET /api/orders/{id}/payment-qr
  Future<PaymentQrModel> getPaymentQr(int orderId) {
    return orderService.getPaymentQr(orderId);
  }
}
