import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Kiểm tra user có phải admin không
  Future<bool> isAdmin(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['isAdmin'] ?? false;
    } catch (e) {
      print('Error checking admin: $e');
      return false;
    }
  }

  /// Set user làm admin (chỉ admin mới làm được)
  Future<void> setAdmin(String userId, bool isAdmin) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
      });
      print('Set admin status for $userId: $isAdmin');
    } catch (e) {
      print('Error setting admin: $e');
      rethrow;
    }
  }

  /// Lấy danh sách tất cả users (admin only)
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromDocument(doc))
            .toList());
  }

  /// Ban user (admin only)
  Future<void> banUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': true,
        'bannedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error banning user: $e');
      rethrow;
    }
  }

  /// Unban user (admin only)
  Future<void> unbanUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBanned': false,
      });
    } catch (e) {
      print('Error unbanning user: $e');
      rethrow;
    }
  }
}
