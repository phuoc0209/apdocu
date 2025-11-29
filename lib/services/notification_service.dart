import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCollection(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items');
  }

  Future<void> addNotification(AppNotification notification) async {
    await _userCollection(notification.userId)
        .doc(notification.id)
        .set(notification.toMap());
  }

  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _userCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromDocument(doc))
            .toList());
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _userCollection(userId)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final query = await _userCollection(userId).where('isRead', isEqualTo: false).get();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}