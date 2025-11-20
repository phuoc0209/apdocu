import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../database/database_service.dart';

class ProductsProvider with ChangeNotifier {
  final List<Product> _items = [];
  final List<Product> _allItems = []; // Lưu tất cả sản phẩm gốc
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  String _sortBy = 'newest'; // newest, price_low, price_high, name
  int? _filterBySellerId; // Filter theo seller_id

  final DatabaseService _dbService = DatabaseService.instance;

  List<Product> get items => List.unmodifiable(_items);
  List<Product> get allItems => List.unmodifiable(_allItems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  int? get filterBySellerId => _filterBySellerId;

  // Danh sách categories
  static const List<String> categories = [
    'Tất cả',
    'Điện tử',
    'Thời trang',
    'Đồ gia dụng',
    'Sách',
    'Thể thao',
    'Xe cộ',
    'Đồ chơi',
    'Khác',
  ];

  ProductsProvider() {
    loadProducts();
  }

  /// Tải danh sách sản phẩm từ database
  Future<void> loadProducts({int? sellerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final products = await _dbService.getAllProducts(sellerId: sellerId);
      _allItems.clear();
      _allItems.addAll(products);
      _applyFilters();
      _errorMessage = null;
    } on SocketException catch (e) {
      _errorMessage = 'Không thể kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.';
      if (kDebugMode) debugPrint('SocketException khi tải sản phẩm: $e');
    } catch (e) {
      _errorMessage = 'Lỗi khi tải sản phẩm: ${e.toString().split('\n').first}';
      if (kDebugMode) debugPrint('Load products error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lọc theo seller_id
  void filterBySeller(int? sellerId) {
    _filterBySellerId = sellerId;
    loadProducts(sellerId: sellerId);
  }

  /// Tìm kiếm sản phẩm
  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Lọc theo category
  void filterByCategory(String? category) {
    _selectedCategory = category == 'Tất cả' ? null : category;
    _applyFilters();
    notifyListeners();
  }

  /// Sắp xếp sản phẩm
  void sort(String sortType) {
    _sortBy = sortType;
    _applyFilters();
    notifyListeners();
  }

  /// Áp dụng tất cả filters và sort
  void _applyFilters() {
    List<Product> filtered = List.from(_allItems);

    // Filter theo search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.title.toLowerCase().contains(_searchQuery) ||
            product.description.toLowerCase().contains(_searchQuery) ||
            product.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter theo category
    if (_selectedCategory != null) {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'newest':
      default:
        // Giữ nguyên thứ tự từ database (mới nhất trước)
        break;
    }

    _items.clear();
    _items.addAll(filtered);
  }

  /// Reset filters
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _sortBy = 'newest';
    _filterBySellerId = null;
    loadProducts();
  }

  /// Thêm sản phẩm mới vào database
  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    List<String> imageUrls = const [],
    String category = 'Khác',
    int? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerEmail,
    String? itemCondition,
    String? itemSize,
    String? exchangeReason,
    double? exchangeValue,
    String? exchangeType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _dbService.addProduct(
        title: title,
        description: description,
        price: price,
        imageUrls: imageUrls,
        category: category,
        sellerId: sellerId,
        sellerName: sellerName,
        sellerPhone: sellerPhone,
        sellerEmail: sellerEmail,
        itemCondition: itemCondition,
        itemSize: itemSize,
        exchangeReason: exchangeReason,
        exchangeValue: exchangeValue,
        exchangeType: exchangeType,
      );

      if (result['success'] == true) {
        // Tải lại danh sách sản phẩm
        await loadProducts();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Lỗi khi thêm sản phẩm';
        return false;
      }
    } on SocketException catch (e) {
      _errorMessage = 'Không thể kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.';
      if (kDebugMode) debugPrint('SocketException khi thêm sản phẩm: $e');
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi: ${e.toString().split('\n').first}';
      if (kDebugMode) debugPrint('Add product error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật sản phẩm
  Future<bool> updateProduct({
    required String productId,
    required int sellerId,
    String? title,
    String? description,
    double? price,
    List<String>? imageUrls,
    String? category,
    String? status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = int.tryParse(productId);
      if (id == null) {
        _errorMessage = 'ID sản phẩm không hợp lệ';
        return false;
      }

      final result = await _dbService.updateProduct(
        productId: id,
        sellerId: sellerId,
        title: title,
        description: description,
        price: price,
        imageUrls: imageUrls,
        category: category,
        status: status,
      );

      if (result['success'] == true) {
        await loadProducts();
        return true;
      } else {
        _errorMessage = result['message'] as String? ?? 'Lỗi khi cập nhật sản phẩm';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi: $e';
      if (kDebugMode) debugPrint('Update product error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xóa sản phẩm
  Future<bool> deleteProduct(String productId, {int? sellerId}) async {
    try {
      final id = int.tryParse(productId);
      if (id == null) return false;

      final success = await _dbService.deleteProduct(id, sellerId: sellerId);
      if (success) {
        await loadProducts();
      }
      return success;
    } catch (e) {
      if (kDebugMode) debugPrint('Delete product error: $e');
      return false;
    }
  }
}
