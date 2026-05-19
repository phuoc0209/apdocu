import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final ApiService _apiService = ApiService();

  Future<void> addNotification(AppNotification notification) async {
    // TODO: Implement API endpoint
    // await _apiService.post('notifications/create.php', notification.toMap());
  }

  Future<List<AppNotification>> getUserNotifications(String userId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('notifications/list.php?userId=$userId');
    // return (response as List).map((e) => AppNotification.fromMap(e)).toList();
    return [];
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('notifications/mark_read.php', {'id': notificationId});
  }

  Future<void> markAllAsRead(String userId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('notifications/mark_all_read.php', {'userId': userId});
  }
}