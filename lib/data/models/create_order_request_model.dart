/// Model từng item khi gửi request tạo đơn hàng
class CreateOrderItemRequest {
  final int productId;
  final int? colorId;
  final int quantity;

  CreateOrderItemRequest({
    required this.productId,
    this.colorId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'colorId': colorId,
      'quantity': quantity,
    };
  }
}

/// Model Request gửi lên API POST /api/orders
class CreateOrderRequestModel {
  final String fullName;
  final String phone;
  final String address;
  final String paymentMethod; // "COD" | "QR"
  final String? voucherCode;
  final List<CreateOrderItemRequest> items;

  CreateOrderRequestModel({
    required this.fullName,
    required this.phone,
    required this.address,
    required this.paymentMethod,
    this.voucherCode,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'paymentMethod': paymentMethod,
      if (voucherCode != null && voucherCode!.trim().isNotEmpty)
        'voucherCode': voucherCode!.trim(),
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
