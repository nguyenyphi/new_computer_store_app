import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/mock/mock_data.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/product_model.dart';

/// Provider quản lý logic Chatbot tư vấn công nghệ máy tính
class ChatbotProvider extends ChangeNotifier {
  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  ChatbotProvider() {
    _initWelcomeMessage();
  }

  /// Khởi tạo câu chào mừng đầu tiên từ AI Bot
  void _initWelcomeMessage() {
    _messages.add(
      ChatMessageModel(
        id: 'msg_0',
        text: 'Xin chào! 👋 Tôi là Trợ lý AI của Cửa Hàng Máy Tính.\n\n'
            'Tôi có thể giúp bạn:\n'
            '• Tư vấn chọn Laptop Gaming, Đồ họa, Văn phòng phù hợp\n'
            '• Gợi ý cấu hình Build PC & Linh kiện tối ưu ngân sách\n'
            '• Giải đáp chính sách bảo hành, đổi trả & khuyến mãi\n'
            '• Hướng dẫn kiểm tra đơn hàng & thanh toán VietQR\n\n'
            'Bạn đang quan tâm đến sản phẩm hoặc dịch vụ nào?',
        sender: ChatSender.bot,
        timestamp: DateTime.now(),
        quickReplies: [
          '🎮 Laptop Gaming',
          '💼 Laptop Mỏng nhẹ',
          '🖥️ PC & Máy trạm',
          '⚡ Card RTX 4070 Ti',
          '🛡️ Chính sách bảo hành',
          '🏷️ Mã giảm giá',
        ],
      ),
    );
  }

  /// Người dùng gửi tin nhắn
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Thêm tin nhắn của User vào danh sách
    final userMsg = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      sender: ChatSender.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    // 2. Tạo hiệu ứng trễ tự nhiên (600ms) để giống AI đang phản hồi
    await Future.delayed(const Duration(milliseconds: 650));

    // 3. Xử lý phản hồi thông minh dựa trên từ khóa câu hỏi
    final botResponse = _generateResponse(trimmed.toLowerCase());

    _isTyping = false;
    _messages.add(botResponse);
    notifyListeners();
  }

  /// Xử lý khi nhấn chip gợi ý nhanh (Quick Reply)
  void selectQuickReply(String reply) {
    sendMessage(reply);
  }

  /// Xóa lịch sử trò chuyện
  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }

  /// Bộ máy phân tích ngôn ngữ tự nhiên và trả lời chuyên sâu về máy tính
  ChatMessageModel _generateResponse(String query) {
    final now = DateTime.now();
    final msgId = 'bot_${now.millisecondsSinceEpoch}';

    // 1. LAPTOP GAMING
    if (query.contains('gaming') || query.contains('game') || query.contains('rog') || query.contains('nitro')) {
      final prods = [
        MockData.findProductById(1), // ASUS ROG Zephyrus G16
        MockData.findProductById(4), // Acer Nitro V 15
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Dành cho nhu cầu chiến game đỉnh cao và đồ họa nặng, '
            'cửa hàng hiện có các mẫu Laptop Gaming nổi bật nhất kèm ưu đãi đặc biệt:\n\n'
            '• **ASUS ROG Zephyrus G16 (2024)**: Màn OLED 240Hz, Core Ultra 9, RTX 4070 siêu mỏng nhẹ.\n'
            '• **Acer Nitro V 15**: Quốc dân phân khúc 20 triệu, Core i5 gen 13 + RTX 4050 tản nhiệt mát mẻ.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['Chi tiết ROG G16', 'Build PC Gaming', 'Mã giảm giá'],
      );
    }

    // 2. LAPTOP VĂN PHÒNG / SINH VIÊN / MỎNG NHẸ / MACBOOK / DELL XPS
    if (query.contains('văn phòng') || query.contains('học tập') || query.contains('macbook') ||
        query.contains('mỏng nhẹ') || query.contains('sinh viên') || query.contains('dell') || query.contains('xps')) {
      final prods = [
        MockData.findProductById(2), // MacBook Air 15 M3
        MockData.findProductById(3), // Dell XPS 14
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Với nhu cầu văn phòng, học tập hoặc doanh nhân cần pin trâu và thiết kế sang trọng:\n\n'
            '• **MacBook Air 15 inch M3 (2024)**: Mỏng chỉ 11.5mm, pin 18 tiếng, màn Liquid Retina sắc nét.\n'
            '• **Dell XPS 14 9440 (2024)**: Thiết kế tương lai với viền vô cực OLED 3.2K 120Hz.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['🎮 Laptop Gaming', 'Xem MacBook Air', 'Mã giảm giá'],
      );
    }

    // 3. PC & MÁY TRẠM / BUILD PC
    if (query.contains('pc') || query.contains('máy trạm') || query.contains('workstation') || query.contains('build')) {
      final prods = [
        MockData.findProductById(5), // PC Gaming Ultra Dragon
        MockData.findProductById(6), // Dell Precision 3660
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Cửa hàng cung cấp các dàn PC ráp sẵn cao cấp và máy trạm đồ họa chuyên nghiệp:\n\n'
            '• **PC Gaming Ultra Dragon**: Intel Core i9-14900K, RTX 4080 Super 16GB, tản nước AIO 360mm.\n'
            '• **Dell Precision 3660 Workstation**: Chuyên dựng hình 3D, kiến trúc, CAD và Render 8K bền bỉ.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['⚡ Card RTX 4070 Ti', 'SSD & RAM', '🛡️ Chính sách bảo hành'],
      );
    }

    // 4. CARD ĐỒ HỌA / GPU / RTX
    if (query.contains('card') || query.contains('vga') || query.contains('gpu') || query.contains('rtx') || query.contains('4070')) {
      final prods = [
        MockData.findProductById(7), // ASUS ROG Strix RTX 4070 Ti SUPER
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Đây là dòng card đồ họa cao cấp đang rất được ưa chuộng:\n\n'
            '• **ASUS ROG Strix GeForce RTX 4070 Ti SUPER 16GB**: Cân tốt mọi tựa game 4K Ray Tracing và Render AI/Video với tản nhiệt 3 quạt Axial-tech mát rượi.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['CPU Core i9', 'SSD Samsung 990 Pro', 'Build PC Gaming'],
      );
    }

    // 5. CPU / CHÍP / PROCESSOR
    if (query.contains('cpu') || query.contains('chip') || query.contains('intel') || query.contains('i9')) {
      final prods = [
        MockData.findProductById(8), // Intel Core i9-14900K
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'CPU hiệu năng hàng đầu hiện nay:\n\n'
            '• **Intel Core i9-14900K**: 24 nhân 32 luồng, xung nhịp turbo lên tới 6.0 GHz, xử lý đa nhiệm cực mượt.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['Card RTX 4070 Ti', 'Build PC Gaming'],
      );
    }

    // 6. SSD / RAM / LINH KIỆN
    if (query.contains('ssd') || query.contains('ổ cứng') || query.contains('ram') || query.contains('bộ nhớ')) {
      final prods = [
        MockData.findProductById(9), // SSD Samsung 990 Pro 2TB
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Linh kiện lưu trữ tốc độ cao nhất thế giới:\n\n'
            '• **SSD Samsung 990 Pro 2TB NVMe PCIe 4.0**: Tốc độ đọc lên tới 7450 MB/s, ghi 6900 MB/s, bảo hành 5 năm chính hãng.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['Linh kiện khác', '🛡️ Chính sách bảo hành'],
      );
    }

    // 7. MÀN HÌNH / MONITOR
    if (query.contains('màn hình') || query.contains('monitor') || query.contains('oled') || query.contains('lg') || query.contains('ultrasharp')) {
      final prods = [
        MockData.findProductById(10), // LG OLED 240Hz
        MockData.findProductById(11), // Dell UltraSharp 2K
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Cửa hàng có 2 dòng màn hình xuất sắc cho từng nhu cầu:\n\n'
            '• **LG UltraGear 27GR95QE-B OLED 240Hz**: Phản hồi 0.03ms siêu nhanh cho game thủ.\n'
            '• **Dell UltraSharp U2724D 2K IPS Black**: Chuẩn màu 100% sRGB & DCI-P3 cho đồ họa chuyên nghiệp.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['Bàn phím & Chuột', 'Laptop Đồ họa'],
      );
    }

    // 8. BÀN PHÍM / CHUỘT / PHỤ KIỆN
    if (query.contains('bàn phím') || query.contains('chuột') || query.contains('keyboard') || query.contains('mouse') || query.contains('phụ kiện')) {
      final prods = [
        MockData.findProductById(12), // Logitech G913 TKL
        MockData.findProductById(13), // Razer DeathAdder V3 Pro
      ].whereType<ProductModel>().toList();

      return ChatMessageModel(
        id: msgId,
        text: 'Bộ đôi ngoại vi gaming không dây đỉnh cao:\n\n'
            '• **Logitech G913 TKL Lightspeed**: Phím cơ Low Profile siêu mỏng, vỏ nhôm phay xước đẳng cấp.\n'
            '• **Razer DeathAdder V3 Pro**: Trọng lượng chỉ 63g, mắt đọc Focus Pro 30K cực chuẩn xác.',
        sender: ChatSender.bot,
        timestamp: now,
        recommendedProducts: prods,
        quickReplies: ['🎮 Laptop Gaming', 'Mã giảm giá'],
      );
    }

    // 9. CHÍNH SÁCH BẢO HÀNH & ĐỔI TRẢ
    if (query.contains('bảo hành') || query.contains('đổi trả') || query.contains('chính sách') || query.contains('sửa')) {
      return ChatMessageModel(
        id: msgId,
        text: '🛡️ **Chính sách bán hàng & bảo hành tại Cửa Hàng Máy Tính:**\n\n'
            '1. **1 đổi 1 trong 30 ngày**: Nếu sản phẩm phát sinh lỗi phần cứng từ nhà sản xuất.\n'
            '2. **Bảo hành chính hãng 12 - 36 tháng**: Tại các trung tâm bảo hành ủy quyền toàn quốc (ASUS, Dell, Apple, HP, MSI, LG...).\n'
            '3. **Hỗ trợ trọn đời**: Miễn phí cài đặt Windows bản quyền, phần mềm văn phòng cơ bản và vệ sinh tra keo tản nhiệt định kỳ.\n'
            '4. **Hotline kỹ thuật**: 1900 6868 (8:00 - 21:00 hàng ngày).',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['🏷️ Mã giảm giá', 'Giao hàng bao lâu?', 'Hướng dẫn thanh toán'],
      );
    }

    // 10. MÃ GIẢM GIÁ / VOUCHER / KHUYẾN MÃI
    if (query.contains('mã') || query.contains('voucher') || query.contains('giảm giá') || query.contains('khuyến mãi') || query.contains('ưu đãi')) {
      return ChatMessageModel(
        id: msgId,
        text: '🎉 **Các mã ưu đãi hiện đang áp dụng:**\n\n'
            '• `SINHVIEN10` : Giảm ngay 10% trên tổng giá trị đơn hàng (áp dụng cho sinh viên).\n'
            '• `HE2026` : Giảm trực tiếp 500.000 VNĐ cho đơn từ 15.000.000 VNĐ.\n'
            '• `FREESHIP` : Miễn phí 100% cước vận chuyển toàn quốc.\n\n'
            '👉 Bạn chỉ cần nhập mã tại bước **Thanh Toán (Checkout)** để nhận giảm giá ngay!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['🎮 Laptop Gaming', '💼 Laptop Mỏng nhẹ', 'Đặt hàng ngay'],
      );
    }

    // 11. GIAO HÀNG / VẬN CHUYỂN
    if (query.contains('giao hàng') || query.contains('ship') || query.contains('vận chuyển') || query.contains('thời gian')) {
      return ChatMessageModel(
        id: msgId,
        text: '🚚 **Thời gian & Cước phí giao hàng:**\n\n'
            '• **Nội thành TP.HCM & Hà Nội**: Giao siêu tốc trong 2 giờ hoặc trong ngày.\n'
            '• **Các tỉnh thành khác**: Giao nhanh từ 1 - 3 ngày làm việc qua bưu điện/chuyển phát nhanh uy tín.\n'
            '• **Phí ship**: Miễn phí hoàn toàn cho đơn từ 2.000.000 VNĐ (đơn dưới 2 triệu phí chỉ 30.000 VNĐ).',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['Hướng dẫn thanh toán', '🛡️ Chính sách bảo hành'],
      );
    }

    // 12. THANH TOÁN / VIETQR / COD
    if (query.contains('thanh toán') || query.contains('qr') || query.contains('vietqr') || query.contains('cod') || query.contains('tiền mặt')) {
      return ChatMessageModel(
        id: msgId,
        text: '💳 **Phương thức thanh toán linh hoạt:**\n\n'
            '1. **Chuyển khoản VietQR**: Ứng dụng tự động sinh mã QR ngân hàng có sẵn số tiền và nội dung đơn. Bạn chỉ cần mở app Mobile Banking quét mã là xong!\n'
            '2. **Thanh toán khi nhận hàng (COD)**: Kiểm tra máy tính đúng mẫu mã trước khi thanh toán tiền mặt cho shipper.',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['🏷️ Mã giảm giá', '🎮 Xem Laptop'],
      );
    }

    // 13. CÂU HỎI MẶC ĐỊNH / CHUNG
    return ChatMessageModel(
      id: msgId,
      text: 'Cảm ơn bạn đã nhắn tin! Tôi có thể tư vấn chi tiết hơn nếu bạn chia sẻ cụ thể:\n'
          '• Mức ngân sách dự kiến (ví dụ: tầm 20 - 30 triệu)?\n'
          '• Mục đích sử dụng chính (Gaming, Học tập lập trình, Đồ họa đồ án hay Văn phòng)?\n'
          '• Hoặc bạn có thể chọn các gợi ý nhanh dưới đây:',
      sender: ChatSender.bot,
      timestamp: now,
      quickReplies: [
        '🎮 Laptop Gaming',
        '💼 Laptop Mỏng nhẹ',
        '🖥️ PC & Máy trạm',
        '🛡️ Chính sách bảo hành',
        '🏷️ Mã giảm giá',
      ],
    );
  }
}
