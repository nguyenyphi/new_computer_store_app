/// Model thông tin thanh toán mã QR chuyển khoản ngân hàng
class PaymentQrModel {
  final int orderId;
  final String qrImageUrl;
  final double amount;
  final String transferContent;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String status;
  final String paymentStatus;

  PaymentQrModel({
    required this.orderId,
    required this.qrImageUrl,
    required this.amount,
    required this.transferContent,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.status = 'Pending',
    this.paymentStatus = 'Pending',
  });

  bool get isPaid => paymentStatus == 'Paid';

  factory PaymentQrModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] != null
        ? (json['amount'] as num).toDouble()
        : (json['totalPrice'] != null ? (json['totalPrice'] as num).toDouble() : 0.0);

    return PaymentQrModel(
      orderId: json['orderId'] != null ? (json['orderId'] as num).toInt() : 0,
      qrImageUrl: json['qrImageUrl'] as String? ??
          json['fallbackQrImageUrl'] as String? ??
          json['qrCode'] as String? ??
          '',
      amount: rawAmount,
      transferContent: json['transferContent'] as String? ??
          'Thanh toan don hang #${json['orderId'] ?? ""}',
      bankName: json['bankName'] as String? ?? 'MoMo',
      accountNumber: json['accountNumber'] as String? ?? '0845644491',
      accountName: json['accountName'] as String? ?? 'Võ Anh Tuấn',
      status: json['status'] as String? ??
          json['orderStatus'] as String? ??
          'Pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'qrImageUrl': qrImageUrl,
      'amount': amount,
      'transferContent': transferContent,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'status': status,
      'paymentStatus': paymentStatus,
    };
  }
}
