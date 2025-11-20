import 'package:flutter/foundation.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    DateTime? timestamp,
    this.read = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationsProvider with ChangeNotifier {
  final List<NotificationItem> _items = [];

  List<NotificationItem> get items => List.unmodifiable(_items.reversed);

  int get unreadCount => _items.where((n) => !n.read).length;

  void add(NotificationItem item) {
    _items.add(item);
    notifyListeners();
  }

  void markRead(String id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i >= 0 && !_items[i].read) {
      _items[i].read = true;
      notifyListeners();
    }
  }

  void markAllRead() {
    var changed = false;
    for (var e in _items) {
      if (!e.read) {
        e.read = true;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void remove(String id) {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // For demo: seed some sample notifications
  void seedSample() {
    _items.clear();
    add(NotificationItem(id: 'n1', title: 'Chào mừng', body: 'Cảm ơn bạn đã đăng ký trên Appdocu!'));
    add(NotificationItem(id: 'n2', title: 'Có đề nghị', body: 'Bạn vừa nhận được đề nghị cho listing của bạn.'));
    add(NotificationItem(id: 'n3', title: 'Thông báo bảo mật', body: 'Hãy bật xác thực 2 bước để bảo mật tài khoản.'));
  }
}
