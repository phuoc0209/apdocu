import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../utils/language_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lp = LanguageProvider();
    final user = AuthService().currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem thông báo')),
      );
    }

    final notificationService = NotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E335A),
        centerTitle: true,
        title: Text(
          lp.translate('notifications'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notificationService.markAllAsRead(user.uid);
            },
            child: Text(
              lp.translate('mark_all_read'),
              style: const TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: notificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF6C63FF),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      lp.translate('no_notifications_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E335A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lp.translate('no_notifications_body'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8389A8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(notification: n);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({Key? key, required this.notification})
      : super(key: key);

  IconData _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.postPending:
        return Icons.hourglass_top_rounded;
      case AppNotificationType.postApproved:
        return Icons.verified_rounded;
      case AppNotificationType.postRejected:
        return Icons.block_rounded;
      case AppNotificationType.newFollower:
        return Icons.person_add_alt_1_rounded;
      case AppNotificationType.newComment:
        return Icons.chat_bubble_outline_rounded;
      case AppNotificationType.sellerReviewed:
        return Icons.star_rate_rounded;
    }
  }

  Color _iconColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.postPending:
        return const Color(0xFFFFA726);
      case AppNotificationType.postApproved:
        return const Color(0xFF4CAF50);
      case AppNotificationType.postRejected:
        return const Color(0xFFE53935);
      case AppNotificationType.newFollower:
        return const Color(0xFF6C63FF);
      case AppNotificationType.newComment:
        return const Color(0xFF29B6F6);
      case AppNotificationType.sellerReviewed:
        return const Color(0xFFFFC857);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final service = NotificationService();

    return InkWell(
      onTap: () async {
        if (user != null && !notification.isRead) {
          await service.markAsRead(user.uid, notification.id);
        }
        // Điều hướng theo loại thông báo
        if (notification.relatedProductId != null) {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: notification.relatedProductId,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              notification.isRead ? Colors.white : const Color(0xFFEAF0FF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(notification.type).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(notification.type),
                color: _iconColor(notification.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E335A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6F8D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(notification.createdAt, locale: 'vi'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9AA0C2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
