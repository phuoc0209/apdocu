import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notifications.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // seed sample notifications for demo if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<NotificationsProvider>(context, listen: false);
      if (prov.items.isEmpty) prov.seedSample();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            tooltip: 'Đánh dấu tất cả là đã đọc',
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => Provider.of<NotificationsProvider>(context, listen: false).markAllRead(),
          ),
          IconButton(
            tooltip: 'Xóa tất cả',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: Consumer<NotificationsProvider>(
        builder: (ctx, prov, _) {
          final items = prov.items;
          if (items.isEmpty) return const Center(child: Text('Không có thông báo'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final it = items[i];
              return NotificationTile(
                item: it,
                onTap: () => prov.markRead(it.id),
                onRemove: () => prov.remove(it.id),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) async {
    final prov = Provider.of<NotificationsProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text('Bạn có chắc muốn xóa tất cả thông báo không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) prov.clear();
  }
}
