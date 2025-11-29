import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  postPending,
  postApproved,
  postRejected,
  newFollower,
  newComment,
}

class AppNotification {
  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? relatedProductId;
  final String? relatedUserId;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.relatedProductId,
    this.relatedUserId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'relatedProductId': relatedProductId,
      'relatedUserId': relatedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: _typeFromString(map['type']),
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      relatedProductId: map['relatedProductId'],
      relatedUserId: map['relatedUserId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification.fromMap({...data, 'id': doc.id});
  }

  static AppNotificationType _typeFromString(String? value) {
    switch (value) {
      case 'postPending':
        return AppNotificationType.postPending;
      case 'postApproved':
        return AppNotificationType.postApproved;
      case 'postRejected':
        return AppNotificationType.postRejected;
      case 'newFollower':
        return AppNotificationType.newFollower;
      case 'newComment':
        return AppNotificationType.newComment;
      default:
        return AppNotificationType.postPending;
    }
  }
}