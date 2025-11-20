import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat trợ lý AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Messages list (newest at bottom)
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: chat.messages.length,
              itemBuilder: (ctx, i) {
                // show newest at bottom
                final msg = chat.messages[chat.messages.length - 1 - i];
                return ChatBubble(message: msg.text, fromUser: msg.fromUser, time: msg.time);
              },
            ),
          ),

          // Input area with safe handling of keyboard
          AnimatedPadding(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0x08000000), blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.message_outlined, color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              decoration: const InputDecoration(
                                hintText: 'Gõ tin nhắn... (ví dụ: Xin chào)',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onSubmitted: _send,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _send(_ctrl.text),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    Provider.of<ChatProvider>(context, listen: false).addUserMessage(t);
    _ctrl.clear();
  }
}
