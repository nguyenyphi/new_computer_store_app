import '../mock/mock_data.dart';
import '../models/create_order_request_model.dart';
import '../models/order_model.dart';
import '../models/payment_qr_model.dart';
import '../services/order_service.dart';

/// Repository quản lý nghiệp vụ Đơn hàng và Thanh toán
/// Hỗ trợ fallback thông minh để luôn tạo đơn và xem mã VietQR thành công khi offline
class OrderRepository {
  final OrderService orderService;
  final List<OrderModel> _demoOrders = [];

  OrderRepository({required this.orderService});

  /// Tạo đơn hàng mới
  Future<OrderModel> createOrder(CreateOrderRequestModel request) async {
    try {
      return await orderService.createOrder(request);
    } catch (_) {
      // Khi server backend LAN offline -> Tạo đơn hàng demo
      final newOrderId = 1000 + _demoOrders.length + 1;
      double total = 0;
      final details = <OrderDetailModel>[];

      for (int i = 0; i < request.items.length; i++) {
        final item = request.items[i];
        final product = MockData.findProductById(item.productId);
        final itemPrice = product?.finalPrice ?? 49491000.0;
        final itemTotal = itemPrice * item.quantity;
        total += itemTotal;

        String? colorName;
        String? colorCode;
        if (product != null && item.colorId != null) {
          final matchedColor =
              product.productColors.where((c) => c.id == item.colorId);
          if (matchedColor.isNotEmpty) {
            colorName = matchedColor.first.colorName;
            colorCode = matchedColor.first.colorCode;
          }
        }

        details.add(
          OrderDetailModel(
            orderDetailId: i + 1,
            productId: item.productId,
            productName: product?.productName ?? 'Sản phẩm máy tính',
            imageUrl: product?.imageUrl,
            colorName: colorName,
            colorCode: colorCode,
            quantity: item.quantity,
            price: product?.price ?? itemPrice,
            finalPrice: itemPrice,
          ),
        );
      }

      final demoOrder = OrderModel(
        orderId: newOrderId,
        orderDate: DateTime.now(),
        totalPrice: total,
        status: 'Pending',
        fullName: request.fullName,
        phone: request.phone,
        address: request.address,
        paymentMethod: request.paymentMethod,
        paymentStatus: 'Pending',
        orderDetails: details,
      );

      _demoOrders.insert(0, demoOrder);
      return demoOrder;
    }
  }

  /// Lấy danh sách lịch sử đơn hàng
  Future<List<OrderModel>> getOrders() async {
    try {
      final remoteOrders = await orderService.getOrders();
      if (remoteOrders.isNotEmpty) return remoteOrders;
    } catch (_) {
      // Khi server backend LAN offline -> Trả về đơn hàng demo
    }
    return _demoOrders;
  }

  /// Lấy chi tiết đơn hàng
  Future<OrderModel> getOrderDetails(int orderId) async {
    try {
      return await orderService.getOrderDetails(orderId);
    } catch (_) {
      final found = _demoOrders.where((o) => o.orderId == orderId);
      if (found.isNotEmpty) return found.first;
      if (_demoOrders.isNotEmpty) return _demoOrders.first;
      rethrow;
    }
  }

  /// Lấy mã QR thanh toán
  Future<PaymentQrModel> getPaymentQr(int orderId) async {
    try {
      return await orderService.getPaymentQr(orderId);
    } catch (_) {
      final found = _demoOrders.where((o) => o.orderId == orderId);
      final amount = found.isNotEmpty ? found.first.totalPrice : 49491000.0;
      final amountInt = amount.toInt();

      return PaymentQrModel(
        orderId: orderId,
        amount: amount,
        bankName: 'MBBank (Ngân hàng TMCP Quân Đội)',
        accountNumber: '0388166999',
        accountName: 'NGUYEN Y PHI',
        transferContent: 'DH$orderId',
        qrImageUrl:
            'https://img.vietqr.io/image/MB-0388166999-compact2.png?amount=$amountInt&addInfo=DH$orderId&accountName=NGUYEN%20Y%20PHI',
      );
    }
  }
}
