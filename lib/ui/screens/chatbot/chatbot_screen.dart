import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/chatbot_provider.dart';

/// Màn hình Chatbot Tư vấn AI Máy Tính & Linh Kiện
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(ChatbotProvider bot) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    bot.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bot = context.watch<ChatbotProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cuộn xuống khi có tin nhắn mới hoặc bot đang gõ
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (isDark ? AppColors.primaryDark : AppColors.primary)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ Lý AI Máy Tính',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tư vấn trực tuyến 24/7 • Sẵn sàng',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới cuộc trò chuyện',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Làm mới hội thoại?'),
                  content: const Text(
                      'Toàn bộ lịch sử trò chuyện hiện tại sẽ được khởi động lại.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        bot.clearChat();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Làm mới'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: bot.messages.length + (bot.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == bot.messages.length && bot.isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                final msg = bot.messages[index];
                return _buildMessageItem(context, msg, isDark, bot);
              },
            ),
          ),

          // 2. Thanh nhập tin nhắn và gợi ý nhanh
          _buildInputArea(context, bot, isDark),
        ],
      ),
    );
  }

  /// Widget hiển thị từng tin nhắn (User hoặc AI Bot)
  Widget _buildMessageItem(
    BuildContext context,
    ChatMessageModel msg,
    bool isDark,
    ChatbotProvider bot,
  ) {
    if (msg.isUser) {
      // --- TIN NHẮN TỪ NGƯỜI DÙNG (Bên phải) ---
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 48),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // --- TIN NHẮN TỪ TRỢ LÝ AI (Bên trái) ---
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    (isDark ? AppColors.primaryDark : AppColors.primary)
                        .withValues(alpha: 0.15),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: isDark ? AppColors.primaryDark : AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Hiển thị sản phẩm gợi ý nếu có
          if (msg.recommendedProducts != null &&
              msg.recommendedProducts!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 10),
              child: SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: msg.recommendedProducts!.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (ctx, idx) {
                    final p = msg.recommendedProducts![idx];
                    return _buildMiniProductCard(ctx, p, isDark);
                  },
                ),
              ),
            ),

          // Hiển thị danh sách câu hỏi gợi ý nhanh (Quick Replies)
          if (msg.quickReplies != null && msg.quickReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: msg.quickReplies!.map((reply) {
                  return ActionChip(
                    label: Text(
                      reply,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    onPressed: () => bot.selectQuickReply(reply),
                    backgroundColor:
                        isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  /// Card sản phẩm thu nhỏ được nhúng trong bong bóng chat
  Widget _buildMiniProductCard(
    BuildContext context,
    ProductModel product,
    bool isDark,
  ) {
    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sản phẩm
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: product.imageUrl != null &&
                      product.imageUrl!.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(color: Colors.grey.shade200),
                      errorWidget: (_, _, _) => const Icon(Icons.computer, size: 36),
                    )
                  : const Icon(Icons.computer, size: 36),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(product.finalPrice),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          isDark ? AppColors.primaryDark : AppColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      context.push('/product/${product.productId}');
                    },
                    child: const Text('Xem chi tiết'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hiệu ứng ba chấm khi AI đang suy nghĩ / soạn câu trả lời
  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                (isDark ? AppColors.primaryDark : AppColors.primary)
                    .withValues(alpha: 0.15),
            child: Icon(
              Icons.smart_toy_rounded,
              color: isDark ? AppColors.primaryDark : AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Trợ lý đang phản hồi...',
                  style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khung nhập tin nhắn
  Widget _buildInputArea(
    BuildContext context,
    ChatbotProvider bot,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(bot),
                  decoration: const InputDecoration(
                    hintText: 'Hỏi về Laptop, PC, Bảo hành, Voucher...',
                    hintStyle: TextStyle(fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  isDark ? AppColors.primaryDark : AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: () => _handleSend(bot),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
