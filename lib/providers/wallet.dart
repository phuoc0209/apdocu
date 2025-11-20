import 'package:flutter/foundation.dart';
import '../database/database_service.dart';

class WalletProvider with ChangeNotifier {
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService.instance;

  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  /// Tải số dư ví
  Future<void> loadBalance(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _balance = await _dbService.getWalletBalance(userId);
    } catch (e) {
      if (kDebugMode) debugPrint('Load balance error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải lịch sử giao dịch
  Future<void> loadTransactions(int userId, {int? limit}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbService.getWalletTransactions(userId, limit: limit);
    } catch (e) {
      if (kDebugMode) debugPrint('Load transactions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nạp tiền
  Future<Map<String, dynamic>> deposit(int userId, double amount, {String? description}) async {
    try {
      final result = await _dbService.depositWallet(
        userId: userId,
        amount: amount,
        description: description,
      );
      if (result['success'] == true) {
        _balance = result['balance'] as double;
        await loadTransactions(userId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Rút tiền
  Future<Map<String, dynamic>> withdraw(int userId, double amount, {String? description}) async {
    try {
      final result = await _dbService.withdrawWallet(
        userId: userId,
        amount: amount,
        description: description,
      );
      if (result['success'] == true) {
        _balance = result['balance'] as double;
        await loadTransactions(userId);
        notifyListeners();
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}

