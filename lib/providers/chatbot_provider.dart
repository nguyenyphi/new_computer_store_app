import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/currency_formatter.dart';
import '../data/models/category_model.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/product_model.dart';
import '../data/repositories/catalog_repository.dart';

/// Provider quản lý logic Chatbot tư vấn.
/// Sản phẩm gợi ý được lấy TRỰC TIẾP từ API Backend (sản phẩm cửa hàng đang đăng bán),
/// không dùng dữ liệu mẫu.
class ChatbotProvider extends ChangeNotifier {
  final CatalogRepository catalogRepository;

  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;

  /// Bộ nhớ đệm sản phẩm & danh mục thật lấy từ server
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  DateTime? _loadedAt;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  ChatbotProvider({required this.catalogRepository}) {
    _initWelcomeMessage();
    _loadCatalog();
  }

  /// Gợi ý nhanh: sinh từ danh mục thật trên server
  List<String> get _defaultQuickReplies => [
    ..._categories.take(4).map((c) => c.categoryName),
    '🔥 Sản phẩm đang giảm giá',
    '💰 Dưới 20 triệu',
    '🛡️ Chính sách bảo hành',
    '🏷️ Mã giảm giá',
  ];

  /// Tải danh mục & toàn bộ sản phẩm đang bán (cache 2 phút)
  Future<void> _loadCatalog({bool force = false}) async {
    if (!force &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 2)) {
      return;
    }
    try {
      final results = await Future.wait([
        catalogRepository.getCategories(),
        catalogRepository.getProducts(page: 1, pageSize: 200),
      ]);
      _categories = results[0] as List<CategoryModel>;
      _products = (results[1] as dynamic).items as List<ProductModel>;
      _loadedAt = DateTime.now();
      // Cập nhật lại chip gợi ý của lời chào theo danh mục thật
      if (_messages.length == 1 && _messages.first.id == 'msg_0') {
        _messages
          ..clear()
          ..add(_welcome());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Chatbot: không tải được sản phẩm từ server: $e');
    }
  }

  ChatMessageModel _welcome() => ChatMessageModel(
    id: 'msg_0',
    text:
        'Xin chào! 👋 Tôi là Trợ lý AI của Cửa Hàng Máy Tính.\n\n'
        'Tôi có thể giúp bạn:\n'
        '• Tìm sản phẩm cửa hàng đang bán theo tên, danh mục hoặc ngân sách\n'
        '• Gợi ý sản phẩm đang giảm giá\n'
        '• Giải đáp chính sách bảo hành, đổi trả & khuyến mãi\n'
        '• Hướng dẫn kiểm tra đơn hàng & thanh toán VietQR\n\n'
        'Bạn đang quan tâm đến sản phẩm nào? (VD: "MacBook", "iPad", "dưới 20 triệu")',
    sender: ChatSender.bot,
    timestamp: DateTime.now(),
    quickReplies: _defaultQuickReplies,
  );

  /// Khởi tạo câu chào mừng đầu tiên từ AI Bot
  void _initWelcomeMessage() {
    _messages.add(_welcome());
  }

  /// Người dùng gửi tin nhắn
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(
      ChatMessageModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: trimmed,
        sender: ChatSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isTyping = true;
    notifyListeners();

    // Đảm bảo đã có dữ liệu sản phẩm thật (tải lại nếu cache cũ hoặc lần trước lỗi)
    await Future.wait([
      _loadCatalog(),
      Future.delayed(const Duration(milliseconds: 500)),
    ]);

    final botResponse = _generateResponse(trimmed.toLowerCase());

    _isTyping = false;
    _messages.add(botResponse);
    notifyListeners();
  }

  /// Xử lý khi nhấn chip gợi ý nhanh (Quick Reply)
  void selectQuickReply(String reply) {
    sendMessage(reply);
  }

  /// Xóa lịch sử trò chuyện (tải lại sản phẩm mới nhất từ server)
  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
    _loadCatalog(force: true);
  }

  /// Phân tích câu hỏi và trả lời
  ChatMessageModel _generateResponse(String query) {
    final now = DateTime.now();
    final msgId = 'bot_${now.millisecondsSinceEpoch}';
    final qNorm = ' ${_norm(query).replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim()} ';

    // 1. CHÀO HỎI ĐƠN GIẢN (xin chào, hello, hi, alo, chào shop...)
    if (_isExactOrStartsWith(qNorm, [
          'xin chao',
          'chao',
          'hello',
          'hi',
          'hey',
          'alo',
          'helo',
          'chao shop',
          'chao ban',
          'chao ad',
          'shop oi',
          'ad oi',
          'bot oi',
          'co ai khong',
        ]) &&
        qNorm.trim().split(' ').length <= 4) {
      return ChatMessageModel(
        id: msgId,
        text:
            'Chào bạn! 👋 Rất vui được hỗ trợ bạn tại **Cửa Hàng Máy Tính**.\n\n'
            'Hiện cửa hàng đang có sẵn **${_products.length} sản phẩm** thuộc các danh mục: '
            '**${_categories.map((c) => c.categoryName).join(", ")}**.\n\n'
            'Bạn đang tìm máy trong tầm giá bao nhiêu hoặc dùng cho nhu cầu gì (học tập, văn phòng, đồ họa, giải trí) để mình tư vấn ngay nhé?',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: _defaultQuickReplies,
      );
    }

    // 2. HỎI THĂM / LÀM QUEN (bạn là ai, tên gì, khỏe không, làm được gì...)
    if (_hasAny(qNorm, [
      'ban la ai',
      'ten gi',
      'la gi',
      'khoe khong',
      'lam duoc gi',
      'giup gi',
      'biet lam gi',
      'thong minh',
    ])) {
      return ChatMessageModel(
        id: msgId,
        text:
            'Mình là **Trợ lý AI của Cửa Hàng Máy Tính** 🤖!\n\n'
            'Mình được kết nối trực tiếp với kho hàng của shop nên có thể:\n'
            '• Báo giá chính xác & kiểm tra tồn kho từng mẫu Laptop, MacBook, iPad\n'
            '• Tìm máy rẻ nhất, cao cấp nhất hoặc lọc theo ngân sách (VD: *"dưới 20 triệu"*)\n'
            '• Cung cấp mã giảm giá, chính sách bảo hành & hướng dẫn thanh toán QR\n\n'
            'Bạn thử hỏi mình một câu nhé!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: _defaultQuickReplies,
      );
    }

    // 3. CẢM ƠN / KHEN NGỢI / ĐỒNG Ý (cảm ơn, thanks, ok, tuyệt vời...)
    if (_isExactOrStartsWith(qNorm, [
          'cam on',
          'thank',
          'thanks',
          'tks',
          'ok',
          'oke',
          'okay',
          'tot qua',
          'hay qua',
          'tuyet voi',
          'duoc roi',
          'da hieu',
        ]) &&
        qNorm.trim().split(' ').length <= 5) {
      return ChatMessageModel(
        id: msgId,
        text:
            'Không có gì đâu ạ! 😊 Rất vui vì đã giúp được bạn.\n'
            'Nếu cần xem thêm sản phẩm nào hoặc hỗ trợ đặt hàng, bạn cứ nhắn mình bất cứ lúc nào nhé!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: _defaultQuickReplies,
      );
    }

    // 4. TẠM BIỆT (tạm biệt, bye, hẹn gặp lại...)
    if (_isExactOrStartsWith(qNorm, [
          'tam biet',
          'bye',
          'goodbye',
          'pp',
          'hen gap lai',
          'chao tam biet',
        ]) &&
        qNorm.trim().split(' ').length <= 4) {
      return ChatMessageModel(
        id: msgId,
        text:
            'Tạm biệt bạn! 👋 Chúc bạn một ngày tốt lành. Hẹn gặp lại bạn tại **Cửa Hàng Máy Tính** nhé!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: _defaultQuickReplies,
      );
    }

    // 5. ĐỊA CHỈ / LIÊN HỆ / GIỜ MỞ CỬA / HOTLINE
    if (_hasAny(qNorm, [
      'dia chi',
      'o dau',
      'chi nhanh',
      'cua hang o',
      'so dien thoai',
      'hotline',
      'lien he',
      'zalo',
      'email',
      'gio mo cua',
      'may gio',
      'lam viec',
    ])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '📍 **Thông tin liên hệ Cửa Hàng Máy Tính:**\n\n'
            '• **Địa chỉ Showroom**: Khu Công nghệ cao, TP. Thủ Đức, TP.HCM\n'
            '• **Hotline tư vấn & kỹ thuật**: 0845 644 491 – 1900 6868\n'
            '• **Giờ mở cửa**: 08:00 – 21:30 (Tất cả các ngày trong tuần, kể cả Lễ & Chủ nhật)\n'
            '• **Hỗ trợ đặt hàng Online**: Giao nhanh toàn quốc trên ứng dụng 24/7!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: [
          '🚚 Thời gian giao hàng',
          '🛡️ Chính sách bảo hành',
          '🏷️ Mã giảm giá',
        ],
      );
    }

    // 6. CÁCH ĐẶT HÀNG / MUA HÀNG / THEO DÕI ĐƠN
    if (_hasAny(qNorm, [
      'cach mua',
      'cach dat',
      'dat hang ngay',
      'lam sao mua',
      'mua nhu the nao',
      'huong dan mua',
      'kiem tra don',
      'xem don hang',
      'theo doi don',
    ])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '🛒 **Hướng dẫn đặt hàng cực dễ chỉ với 3 bước:**\n\n'
            '1. Chọn sản phẩm ưng ý → bấm **"Thêm vào giỏ"**.\n'
            '2. Vào tab **Giỏ hàng** → bấm **"Tiến hành đặt hàng"**.\n'
            '3. Điền địa chỉ nhận hàng, nhập mã giảm giá (`SINHVIEN10`, `HE2026`, `FREESHIP`) và chọn **Chuyển khoản VietQR (MoMo)** hoặc **COD**.\n\n'
            '📦 Để xem lại đơn đã đặt hoặc lấy lại mã QR thanh toán, bạn vào tab **"Đơn hàng"** ở thanh menu dưới cùng nhé!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: [
          '🏷️ Mã giảm giá',
          '💳 Hướng dẫn thanh toán',
          ..._categories.take(2).map((c) => c.categoryName),
        ],
      );
    }

    // 7. TRẢ GÓP
    if (_hasAny(qNorm, ['tra gop', 'gop 0', 'the tin dung'])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '💳 **Chính sách mua trả góp 0% lãi suất:**\n\n'
            '• Hỗ trợ trả góp **0% lãi suất** qua thẻ tín dụng của hơn 25 ngân hàng.\n'
            '• Hoặc trả góp qua CCCD gắn chip (duyệt hồ sơ nhanh trong 15 phút tại cửa hàng, trả trước chỉ từ 20%).\n'
            '• Sinh viên được ưu đãi duyệt thẳng và vẫn áp dụng kèm mã giảm giá `SINHVIEN10`!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: _defaultQuickReplies,
      );
    }

    // 8. TƯ VẤN THEO NHU CẦU (sinh viên, học tập, văn phòng, đồ họa, gaming...)
    if (_hasAny(qNorm, [
          'sinh vien',
          'hoc tap',
          'van phong',
          'ke toan',
          'code',
          'lap trinh',
          'do hoa',
          'thiet ke',
          'render',
          'gaming',
          'choi game',
          'mong nhe',
          'pin trau',
        ]) &&
        _products.isNotEmpty) {
      return _answerNeedBasedQuestion(qNorm, msgId, now);
    }

    // 9. CHÍNH SÁCH BẢO HÀNH & ĐỔI TRẢ
    if (_hasAny(qNorm, ['bao hanh', 'doi tra', 'chinh sach', 'sua chua', 'loi'])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '🛡️ **Chính sách bán hàng & bảo hành tại Cửa Hàng Máy Tính:**\n\n'
            '1. **1 đổi 1 trong 30 ngày**: Nếu sản phẩm phát sinh lỗi phần cứng từ nhà sản xuất.\n'
            '2. **Bảo hành chính hãng 12 - 36 tháng**: Tại các trung tâm bảo hành ủy quyền toàn quốc (ASUS, Dell, Apple, HP, MSI, LG...).\n'
            '3. **Hỗ trợ trọn đời**: Miễn phí cài đặt Windows bản quyền, phần mềm văn phòng cơ bản và vệ sinh tra keo tản nhiệt định kỳ.\n'
            '4. **Hotline kỹ thuật**: 1900 6868 (8:00 - 21:00 hàng ngày).',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: [
          '🏷️ Mã giảm giá',
          'Giao hàng bao lâu?',
          'Hướng dẫn thanh toán',
        ],
      );
    }

    // 10. MÃ GIẢM GIÁ / VOUCHER / KHUYẾN MÃI
    if (!qNorm.contains('dang giam') &&
        _hasAny(qNorm, ['ma giam', 'voucher', 'giam gia', 'khuyen mai', 'uu dai', 'code giam'])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '🎉 **Các mã ưu đãi hiện đang áp dụng:**\n\n'
            '• `SINHVIEN10` : Giảm ngay 10% trên tổng giá trị đơn hàng (áp dụng cho sinh viên).\n'
            '• `HE2026` : Giảm trực tiếp 500.000 VNĐ cho đơn từ 15.000.000 VNĐ.\n'
            '• `FREESHIP` : Miễn phí 100% cước vận chuyển toàn quốc.\n\n'
            '👉 Bạn chỉ cần nhập mã tại bước **Thanh Toán (Checkout)** để nhận giảm giá ngay!',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: _defaultQuickReplies,
      );
    }

    // 11. GIAO HÀNG / VẬN CHUYỂN
    if (_hasAny(qNorm, ['giao hang', 'ship', 'van chuyen', 'thoi gian giao', 'bao lau nhan'])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '🚚 **Thời gian & Cước phí giao hàng:**\n\n'
            '• **Nội thành TP.HCM & Hà Nội**: Giao siêu tốc trong 2 giờ hoặc trong ngày.\n'
            '• **Các tỉnh thành khác**: Giao nhanh từ 1 - 3 ngày làm việc qua bưu điện/chuyển phát nhanh uy tín.\n'
            '• **Phí ship**: Miễn phí hoàn toàn cho đơn từ 2.000.000 VNĐ (đơn dưới 2 triệu phí chỉ 30.000 VNĐ).',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['Hướng dẫn thanh toán', '🛡️ Chính sách bảo hành'],
      );
    }

    // 12. THANH TOÁN / VIETQR / COD / MOMO
    if (_hasAny(qNorm, ['thanh toan', 'qr', 'vietqr', 'cod', 'tien mat', 'chuyen khoan', 'momo'])) {
      return ChatMessageModel(
        id: msgId,
        text:
            '💳 **Phương thức thanh toán linh hoạt:**\n\n'
            '1. **Chuyển khoản mã QR (MoMo / VietQR)**:\n'
            '   • Ngân hàng / Ví: **MoMo**\n'
            '   • Chủ tài khoản: **Võ Anh Tuấn**\n'
            '   • Số tài khoản: **0845644491**\n'
            '   Ứng dụng tự động sinh mã QR kèm số tiền và nội dung đơn hàng, bạn chỉ cần mở app Ngân hàng hoặc MoMo quét mã là xong!\n'
            '2. **Thanh toán khi nhận hàng (COD)**: Kiểm tra máy đúng mẫu mã trước khi thanh toán tiền mặt cho shipper.',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['🏷️ Mã giảm giá', ..._categories.take(2).map((c) => c.categoryName)],
      );
    }

    // TƯ VẤN SẢN PHẨM: tìm trong sản phẩm thật đang bán
    if (_products.isEmpty) {
      return ChatMessageModel(
        id: msgId,
        text:
            'Xin lỗi, hiện tôi chưa tải được danh sách sản phẩm từ máy chủ 😥\n'
            'Bạn kiểm tra kết nối mạng hoặc vào Cài đặt máy chủ → "Kiểm tra kết nối", rồi hỏi lại nhé.',
        sender: ChatSender.bot,
        timestamp: now,
        quickReplies: ['🛡️ Chính sách bảo hành', '🏷️ Mã giảm giá'],
      );
    }
    return _answerProductQuestion(query, msgId, now);
  }

  // ===================== BỘ HIỂU CÂU HỎI SẢN PHẨM =====================

  /// Bỏ dấu tiếng Việt để so khớp được cả khi người dùng gõ không dấu
  static String _norm(String input) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final sb = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      final idx = from.indexOf(ch);
      sb.write(idx >= 0 ? to[idx] : ch);
    }
    return sb.toString();
  }

  static bool _hasAny(String q, List<String> keys) => keys.any(q.contains);

  static bool _isExactOrStartsWith(String qNorm, List<String> phrases) {
    final trimmed = qNorm.trim();
    return phrases.any(
      (p) => trimmed == p || trimmed.startsWith('$p ') || trimmed.endsWith(' $p'),
    );
  }

  /// Tư vấn thông minh theo nhu cầu sử dụng (học tập/văn phòng vs đồ họa/lập trình/gaming)
  ChatMessageModel _answerNeedBasedQuestion(
    String qNorm,
    String msgId,
    DateTime now,
  ) {
    final pool = _products.where((p) => !p.isOutOfStock).toList();
    final all = pool.isNotEmpty ? pool : _products;

    if (_hasAny(qNorm, ['do hoa', 'thiet ke', 'render', 'gaming', 'choi game', 'lap trinh', 'code'])) {
      final highSpec = [...all]
        ..sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
      final top = highSpec.take(3).toList();
      return _productMessage(
        msgId,
        now,
        'Với nhu cầu **lập trình, đồ họa hoặc xử lý tác vụ nặng**, bạn nên ưu tiên các mẫu có chip mạnh và RAM 16GB trở lên đang có tại cửa hàng:',
        top,
      );
    }

    // Sinh viên, học tập, văn phòng, mỏng nhẹ -> ưu tiên máy gọn nhẹ, giá mềm
    final studentList = [...all]
      ..sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
    final top = studentList.take(4).toList();
    return _productMessage(
      msgId,
      now,
      'Dành cho nhu cầu **sinh viên, học tập và văn phòng mỏng nhẹ**, đây là các mẫu có mức giá tốt và pin bền nhất tại cửa hàng (đừng quên nhập mã `SINHVIEN10` để giảm thêm 10% nhé!):',
      top,
    );
  }

  /// Từ đồng nghĩa / viết tắt hay gặp -> từ có trong tên sản phẩm
  static const Map<String, String> _aliases = {
    'mac': 'macbook',
    'mb': 'macbook',
    'apple': 'macbook ipad iphone',
    'tablet': 'ipad',
    'may tinh bang': 'ipad',
    'dien thoai': 'dien thoai iphone',
    'ip': 'iphone',
    'lap': 'laptop',
    'may tinh xach tay': 'laptop',
    'vivo': 'vivobook',
  };

  static const Set<String> _stopWords = {
    'toi',
    'muon',
    'mua',
    'can',
    'tim',
    'co',
    'khong',
    'cho',
    'xem',
    'shop',
    'cua',
    'hang',
    'nao',
    'loai',
    'gia',
    'bao',
    'nhieu',
    'voi',
    'va',
    'la',
    'mot',
    'cac',
    'nhung',
    'san',
    'pham',
    'ban',
    'dang',
    'chi',
    'tiet',
    'tu',
    'van',
    'giup',
    'minh',
    'em',
    'anh',
    'nhat',
    're',
    'dat',
    'mac',
    'tien',
    'cao',
    'thap',
    'xin',
    'hon',
    'duoi',
    'tren',
    'tam',
    'khoang',
    'trieu',
    'tr',
    'cu',
    'ok',
    'di',
    'a',
    'nhe',
    'ha',
    'vay',
    'the',
    'gi',
    'nay',
    'laptop',
    'may',
    'tinh',
    'con',
    'goi',
    'y',
    'top',
    'list',
    'danh',
    'sach',
  };

  ChatMessageModel _answerProductQuestion(
    String rawQuery,
    String msgId,
    DateTime now,
  ) {
    var q = ' ${_norm(rawQuery)} ';
    final pool = _products.where((p) => !p.isOutOfStock).toList();
    final all = pool.isNotEmpty ? pool : _products;

    // 1. Ý định sắp xếp
    final wantCheapest = _hasAny(q, [
      ' re nhat',
      'thap nhat',
      're nhut',
      'gia re',
      ' re ',
      'tiet kiem',
      'it tien',
    ]);
    final wantPriciest = _hasAny(q, [
      'dat nhat',
      'mac nhat',
      'cao nhat',
      'tien nhat',
      'xin nhat',
      'manh nhat',
      'cao cap',
      'dat tien',
      'xin xo',
    ]);
    final wantDiscount = _hasAny(q, [
      'dang giam',
      'sale',
      'khuyen mai nhieu',
      'giam nhieu',
    ]);
    final wantAll = _hasAny(q, [
      'tat ca',
      'het san pham',
      'nhung gi',
      'ban gi',
      'co gi',
      'danh sach',
    ]);

    // Bỏ cụm từ chỉ ý định (VD "mắc nhất" -> không bị hiểu nhầm là "Mac")
    for (final ph in [
      're nhat',
      'thap nhat',
      'dat nhat',
      'mac nhat',
      'cao nhat',
      'tien nhat',
      'xin nhat',
      'manh nhat',
      'cao cap',
      'dat tien',
      'gia re',
    ]) {
      q = q.replaceAll(ph, ' ');
    }

    // 2. Ngân sách (dưới / trên / từ X đến Y / tầm X)
    double? minP, maxP;
    final range = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|cu)?\s*(?:den|-|toi)\s*(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|cu)',
    ).firstMatch(q);
    final single = RegExp(r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr|cu)').firstMatch(q);
    double toVnd(String s) => double.parse(s.replaceAll(',', '.')) * 1000000;
    if (range != null) {
      minP = toVnd(range.group(1)!);
      maxP = toVnd(range.group(2)!);
    } else if (single != null) {
      final v = toVnd(single.group(1)!);
      if (_hasAny(q, ['tren', 'hon', 'tu '])) {
        minP = v;
      } else if (_hasAny(q, ['tam', 'khoang', 'quanh'])) {
        minP = v * 0.8;
        maxP = v * 1.15;
      } else {
        maxP = v;
      }
    }

    // 3. Danh mục
    final cats = _categories
        .where((c) => q.contains(_norm(c.categoryName)))
        .toList();
    final catIds = cats.map((c) => c.categoryId).toSet();

    // 4. Từ khóa (đã mở rộng từ đồng nghĩa)
    _aliases.forEach((k, v) {
      if (q.contains(' $k ')) q = q.replaceAll(' $k ', ' $k $v ');
    });
    final words = q
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where(
          (w) =>
              w.length >= 2 &&
              !_stopWords.contains(w) &&
              int.tryParse(w) == null,
        )
        .toSet();

    // 5. Lọc
    var list = all.where((p) {
      if (catIds.isNotEmpty && !catIds.contains(p.categoryId)) return false;
      if (minP != null && p.finalPrice < minP) return false;
      if (maxP != null && p.finalPrice > maxP) return false;
      if (wantDiscount && !p.hasDiscount) return false;
      return true;
    }).toList();

    // Chấm điểm theo từ khóa, chỉ giữ sản phẩm khớp nhiều nhất (tránh lẫn hãng khác)
    int bestScore = 0;
    if (words.isNotEmpty) {
      final scores = {
        for (final p in list)
          p: words
              .where(_norm('${p.productName} ${p.categoryName ?? ''}').contains)
              .length,
      };
      bestScore = scores.values.fold<int>(0, (a, b) => a > b ? a : b);
      if (bestScore > 0) {
        list = list.where((p) => scores[p] == bestScore).toList();
      }
    }

    // Nếu người dùng gõ một câu không khớp với bất kỳ danh mục, ngân sách, ý định hay tên sản phẩm nào
    final hasExplicitIntent =
        wantCheapest || wantPriciest || wantDiscount || wantAll || minP != null || maxP != null || cats.isNotEmpty;
    if (!hasExplicitIntent && words.isNotEmpty && bestScore == 0) {
      final suggest = [...all]
        ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      return _productMessage(
        msgId,
        now,
        'Hiện cửa hàng chưa có sản phẩm nào khớp với từ khóa **"$rawQuery"**.\n'
        'Bạn có thể hỏi mình theo tên hãng (*MacBook, Asus, HP, iPad*), theo ngân sách (*dưới 20 triệu*), hoặc tham khảo các sản phẩm nổi bật đang bán dưới đây nhé:',
        suggest.take(4).toList(),
      );
    }

    // 6. Sắp xếp
    if (wantCheapest) {
      list.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
    } else if (wantPriciest) {
      list.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
    } else if (wantDiscount) {
      list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    }

    // 7. Soạn câu trả lời tự nhiên
    final what = [
      if (cats.isNotEmpty) cats.first.categoryName,
      if (words.isNotEmpty)
        words.where((w) => !_aliases.containsKey(w)).join(' '),
    ].where((e) => e.trim().isNotEmpty).join(' ').trim();
    final subject = what.isEmpty ? 'sản phẩm' : '"$what"';

    if (list.isEmpty) {
      final suggest = [...all]
        ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      return _productMessage(
        msgId,
        now,
        'Hiện cửa hàng chưa có $subject phù hợp yêu cầu của bạn 😥\n'
        'Bạn tham khảo các sản phẩm đang bán dưới đây nhé:',
        suggest.take(3).toList(),
      );
    }

    String intro;
    List<ProductModel> show;
    if ((wantCheapest || wantPriciest) && !wantAll) {
      final p = list.first;
      final label = wantCheapest ? 'rẻ nhất' : 'cao cấp nhất (giá cao nhất)';
      intro =
          '${_cap(subject)} $label hiện có là **${p.productName}** '
          'với giá **${CurrencyFormatter.format(p.finalPrice)}**'
          '${p.hasDiscount ? ' (đã giảm ${p.discountPercent.toStringAsFixed(0)}%, giá gốc ${CurrencyFormatter.format(p.price)})' : ''}.'
          '${p.quantity > 0 ? ' Còn ${p.quantity} sản phẩm trong kho.' : ''}';
      show = list.take(3).toList();
      if (show.length > 1) intro += '\n\nCác lựa chọn tiếp theo:';
    } else {
      final budgetText = minP != null && maxP != null
          ? ' trong khoảng ${CurrencyFormatter.format(minP)} – ${CurrencyFormatter.format(maxP)}'
          : maxP != null
          ? ' dưới ${CurrencyFormatter.format(maxP)}'
          : minP != null
          ? ' từ ${CurrencyFormatter.format(minP)} trở lên'
          : '';
      intro =
          'Cửa hàng đang có **${list.length}** $subject$budgetText'
          '${wantDiscount ? ' đang giảm giá' : ''}:';
      show = list.take(4).toList();
    }

    return _productMessage(
      msgId,
      now,
      intro,
      show,
      listItems: !(wantCheapest || wantPriciest) || show.length > 1,
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  ChatMessageModel _productMessage(
    String id,
    DateTime now,
    String intro,
    List<ProductModel> prods, {
    bool listItems = true,
  }) {
    final lines = prods
        .map((p) {
          final sale = p.hasDiscount
              ? ' (−${p.discountPercent.toStringAsFixed(0)}%)'
              : '';
          return '• ${p.productName}: **${CurrencyFormatter.format(p.finalPrice)}**$sale';
        })
        .join('\n');
    final body = listItems && lines.isNotEmpty ? '$intro\n\n$lines' : intro;
    return ChatMessageModel(
      id: id,
      text: '$body\n\nBấm "Xem chi tiết" để xem cấu hình và đặt mua nhé!',
      sender: ChatSender.bot,
      timestamp: now,
      recommendedProducts: prods,
      quickReplies: [
        if (prods.length > 1) 'Rẻ nhất',
        if (prods.length > 1) 'Đắt nhất',
        ..._defaultQuickReplies,
      ],
    );
  }
}
