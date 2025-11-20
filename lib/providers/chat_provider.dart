import 'dart:async';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime time;

  ChatMessage({required this.text, required this.fromUser, DateTime? time}) : time = time ?? DateTime.now();
}

class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addUserMessage(String text) {
    final msg = ChatMessage(text: text, fromUser: true);
    _messages.add(msg);
    notifyListeners();
    _sendToAi(text);
  }

  // Temporary mock AI responder. Replace with real API call.
  Future<void> _sendToAi(String prompt) async {
    // simulate network latency
    await Future.delayed(const Duration(milliseconds: 800));

    // Simple echo + canned behavior. Replace with OpenAI/other service.
    final replyText = _generateMockReply(prompt);
    _messages.add(ChatMessage(text: replyText, fromUser: false));
    notifyListeners();
  }

  String _generateMockReply(String prompt) {
    final low = prompt.toLowerCase();
    if (low.contains('xin chào') || low.contains('hi') || low.contains('hello')) {
      return 'Chào bạn! Mình có thể giúp gì cho bạn hôm nay?';
    }
    if (low.contains('sản phẩm')) {
      return 'Bạn muốn tìm sản phẩm theo tên hay theo danh mục?';
    }
    return 'Mình đã nhận: "$prompt" — (Trả lời mẫu).';
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
