import 'package:flutter/material.dart';
import '../providers/notifications.dart';

class NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const NotificationTile({super.key, required this.item, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onRemove?.call(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.read ? Colors.grey[300] : const Color(0xFF6C63FF),
          child: Icon(item.read ? Icons.mark_email_read : Icons.notifications, color: Colors.white, size: 20),
        ),
        title: Text(item.title, style: TextStyle(fontWeight: item.read ? FontWeight.normal : FontWeight.w600)),
        subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Text(_timeAgo(item.timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        onTap: onTap,
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    return '${diff.inDays} ngày';
  }
}
