/// Model chi tiết từng sản phẩm trong đơn hàng (OrderDetail)
class OrderDetailModel {
  final int orderDetailId;
  final int productId;
  final String productName;
  final String? imageUrl;
  final String? colorName;
  final String? colorCode;
  final int quantity;
  final double price;
  final double finalPrice;

  OrderDetailModel({
    required this.orderDetailId,
    required this.productId,
    required this.productName,
    this.imageUrl,
    this.colorName,
    this.colorCode,
    required this.quantity,
    required this.price,
    required this.finalPrice,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    String name = json['productName'] as String? ?? '';
    String? img = json['imageUrl'] as String? ?? json['productImageUrl'] as String?;

    if (json['product'] is Map<String, dynamic>) {
      final p = json['product'] as Map<String, dynamic>;
      if (name.isEmpty) name = p['productName'] as String? ?? 'Sản phẩm';
      img ??= p['imageUrl'] as String?;
    }

    final pPrice = json['price'] != null
        ? (json['price'] as num).toDouble()
        : (json['originalPrice'] != null
            ? (json['originalPrice'] as num).toDouble()
            : 0.0);
    final fPrice = json['finalPrice'] != null
        ? (json['finalPrice'] as num).toDouble()
        : pPrice;

    return OrderDetailModel(
      orderDetailId: json['orderDetailId'] != null
          ? (json['orderDetailId'] as num).toInt()
          : (json['id'] != null ? (json['id'] as num).toInt() : 0),
      productId: json['productId'] != null
          ? (json['productId'] as num).toInt()
          : 0,
      productName: name.isNotEmpty ? name : 'Sản phẩm',
      imageUrl: img,
      colorName: json['colorName'] as String?,
      colorCode: json['colorCode'] as String?,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toInt()
          : 1,
      price: pPrice,
      finalPrice: fPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderDetailId': orderDetailId,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'colorName': colorName,
      'colorCode': colorCode,
      'quantity': quantity,
      'price': price,
      'finalPrice': finalPrice,
    };
  }
}

/// Model Đơn hàng (Order)
class OrderModel {
  final int orderId;
  final DateTime orderDate;
  final double totalPrice;
  final String status; // Pending, Processing, Shipped, Delivered, Cancelled
  final String fullName;
  final String phone;
  final String address;
  final String paymentMethod; // COD | QR
  final String paymentStatus; // Pending | Paid
  final String? note;
  final List<OrderDetailModel> orderDetails;
  final int itemCount;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    required this.totalPrice,
    required this.status,
    required this.fullName,
    required this.phone,
    required this.address,
    this.paymentMethod = 'COD',
    this.paymentStatus = 'Pending',
    this.note,
    this.orderDetails = const [],
    int? itemCount,
  }) : itemCount = itemCount ??
            (orderDetails.isNotEmpty
                ? orderDetails.fold(0, (sum, i) => sum + i.quantity)
                : 1);

  bool get isPaid => paymentStatus == 'Paid';
  bool get isPendingPayment => paymentMethod == 'QR' && paymentStatus == 'Pending';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    DateTime date = DateTime.now();
    if (json['orderDate'] != null) {
      date = DateTime.tryParse(json['orderDate'].toString()) ?? DateTime.now();
    }

    List<OrderDetailModel> details = [];
    final rawItems = json['orderDetails'] ?? json['items'];
    if (rawItems is List) {
      details = rawItems
          .map((item) => OrderDetailModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final total = json['totalPrice'] != null
        ? (json['totalPrice'] as num).toDouble()
        : 0.0;

    final count = json['itemCount'] != null
        ? (json['itemCount'] as num).toInt()
        : (json['totalQuantity'] != null
            ? (json['totalQuantity'] as num).toInt()
            : (details.isNotEmpty
                ? details.fold(0, (sum, i) => sum + i.quantity)
                : 1));

    return OrderModel(
      orderId: json['orderId'] != null
          ? (json['orderId'] as num).toInt()
          : (json['id'] != null ? (json['id'] as num).toInt() : 0),
      orderDate: date,
      totalPrice: total,
      status: json['status'] as String? ?? 'Pending',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
      note: json['note'] as String?,
      orderDetails: details,
      itemCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderDate': orderDate.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'note': note,
      'orderDetails': orderDetails.map((e) => e.toJson()).toList(),
      'itemCount': itemCount,
    };
  }
}
