import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool fromUser;
  final DateTime? time;

  const ChatBubble({super.key, required this.message, required this.fromUser, this.time});

  @override
  Widget build(BuildContext context) {
    final bg = fromUser ? const Color(0xFF6C63FF) : Colors.white;
    final txtColor = fromUser ? Colors.white : Colors.black87;
    final align = fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(fromUser ? 16 : 4),
                  topRight: Radius.circular(fromUser ? 4 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: fromUser
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0x08000000),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: Text(
                message,
                style: TextStyle(color: txtColor, fontSize: 14.2, height: 1.35),
              ),
            ),
          ),
          if (time != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 6, right: 6),
              child: Text(
                _formatTime(time!),
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
