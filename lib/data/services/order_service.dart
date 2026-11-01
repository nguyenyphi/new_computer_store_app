import '../../core/network/api_client.dart';
import '../models/create_order_request_model.dart';
import '../models/order_model.dart';
import '../models/payment_qr_model.dart';

/// Dịch vụ kết nối API Đơn hàng & Thanh toán theo docs/API.md
class OrderService {
  final ApiClient apiClient;

  OrderService({required this.apiClient});

  /// Tạo đơn hàng mới: POST /api/orders
  Future<OrderModel> createOrder(CreateOrderRequestModel request) async {
    final response = await apiClient.post(
      '/api/orders',
      data: request.toJson(),
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return OrderModel.fromJson(data);
    }
    throw Exception('Dữ liệu đơn hàng tạo mới không hợp lệ');
  }

  /// Lấy danh sách lịch sử đơn hàng của người dùng: GET /api/orders
  Future<List<OrderModel>> getOrders() async {
    final response = await apiClient.get('/api/orders');

    if (response is List) {
      return response
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Lấy thông tin chi tiết đơn hàng: GET /api/orders/{id}
  Future<OrderModel> getOrderDetails(int orderId) async {
    final response = await apiClient.get('/api/orders/$orderId');

    if (response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return OrderModel.fromJson(data);
    }
    throw Exception('Không tìm thấy thông tin đơn hàng');
  }

  /// Lấy mã VietQR thanh toán: GET /api/orders/{id}/payment-qr
  Future<PaymentQrModel> getPaymentQr(int orderId) async {
    final response = await apiClient.get('/api/orders/$orderId/payment-qr');

    if (response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return PaymentQrModel.fromJson(data);
    }
    throw Exception('Không tìm thấy thông tin mã thanh toán QR');
  }
}
