import '../models/user_model.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _apiService = ApiService();

  /// Kiểm tra user có phải admin không
  Future<bool> isAdmin(String userId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('users/is_admin.php?userId=$userId');
    // return response['isAdmin'] ?? false;
    return false; 
  }

  /// Set user làm admin (chỉ admin mới làm được)
  Future<void> setAdmin(String userId, bool isAdmin) async {
    // TODO: Implement API endpoint
    // await _apiService.post('admin/set_admin.php', {'userId': userId, 'isAdmin': isAdmin});
  }

  /// Lấy danh sách tất cả users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('admin/users.php');
    // return (response as List).map((e) => UserModel.fromMap(e)).toList();
    return [];
  }

  /// Ban user (admin only)
  Future<void> banUser(String userId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('admin/ban_user.php', {'userId': userId});
  }

  /// Unban user (admin only)
  Future<void> unbanUser(String userId) async {
    // TODO: Implement API endpoint
    // await _apiService.post('admin/unban_user.php', {'userId': userId});
  }
}
