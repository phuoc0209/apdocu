import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../database/database_service.dart';

class FavoritesProvider with ChangeNotifier {
  final List<Product> _favorites = [];
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService.instance;

  List<Product> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  /// Tải danh sách yêu thích
  Future<void> loadFavorites(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final products = await _dbService.getFavorites(userId);
      _favorites.clear();
      _favorites.addAll(products);
    } catch (e) {
      if (kDebugMode) print('Load favorites error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm vào yêu thích
  Future<bool> addFavorite(int userId, int productId) async {
    try {
      final result = await _dbService.addFavorite(userId, productId);
      if (result['success'] == true) {
        await loadFavorites(userId);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Add favorite error: $e');
      return false;
    }
  }

  /// Xóa khỏi yêu thích
  Future<bool> removeFavorite(int userId, int productId) async {
    try {
      final result = await _dbService.removeFavorite(userId, productId);
      if (result['success'] == true) {
        _favorites.removeWhere((p) => p.id == productId.toString());
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Remove favorite error: $e');
      return false;
    }
  }

  /// Kiểm tra có trong yêu thích không
  Future<bool> isFavorite(int userId, int productId) async {
    try {
      return await _dbService.isFavorite(userId, productId);
    } catch (e) {
      return false;
    }
  }
}

