import 'product_model.dart';

/// Loại người gửi tin nhắn trong hội thoại
enum ChatSender {
  user,
  bot,
}

/// Model tin nhắn trong hội thoại Chatbot
class ChatMessageModel {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime timestamp;
  final List<ProductModel>? recommendedProducts;
  final List<String>? quickReplies;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.recommendedProducts,
    this.quickReplies,
  });

  bool get isUser => sender == ChatSender.user;
  bool get isBot => sender == ChatSender.bot;
}
