import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// Conditional import: web helper vs stub for other platforms
import '../src/web_oauth_stub.dart'
  if (dart.library.html) '../src/web_oauth_web.dart';
import '../database/database_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _username;
  String? _lastAuthError;
  int? _userId;
  String? _userEmail;
  String? _userPhone;
  String? _avatarUrl;
  String? _fullName;
  double _walletBalance = 0.0;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  int? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get avatarUrl => _avatarUrl;
  String? get fullName => _fullName;
  double get walletBalance => _walletBalance;
  /// Last error message from social auth attempts (if any)
  String? get lastAuthError => _lastAuthError;

  final DatabaseService _dbService = DatabaseService.instance;

  // Đăng nhập với database (hỗ trợ username, email hoặc phone)
  Future<bool> login(String identifier, String password) async {
    _lastAuthError = null;
    
    if (identifier.trim().isEmpty || password.isEmpty) {
      _lastAuthError = 'Vui lòng điền đầy đủ thông tin';
      return false;
    }

    try {
      final result = await _dbService.loginUser(
        identifier: identifier.trim(),
        password: password,
      );

      if (result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>;
        _isLoggedIn = true;
        _username = user['username'] as String;
        _userId = user['id'] as int;
        _userEmail = user['email'] as String?;
        _userPhone = user['phone'] as String?;
        _avatarUrl = user['avatar_url'] as String?;
        _fullName = user['fullName'] as String?;
        _walletBalance = (user['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        notifyListeners();
        return true;
      } else {
        _lastAuthError = result['message'] as String? ?? 'Đăng nhập thất bại';
        return false;
      }
    } on SocketException catch (e) {
      _lastAuthError = 'Không thể kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.';
      if (kDebugMode) print('SocketException khi đăng nhập: $e');
      return false;
    } catch (e) {
      _lastAuthError = 'Lỗi kết nối database: ${e.toString().split('\n').first}';
      if (kDebugMode) print('Login error: $e');
      return false;
    }
  }

  // Đăng ký với database
  Future<bool> register(String username, String password, String email, String phone) async {
    _lastAuthError = null;
    
    // Validation
    final passwordStrong = RegExp(r'(?=.*[0-9])(?=.*[A-Za-z])');
    final emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}');
    final phoneReg = RegExp(r'^[0-9]{7,15}$');

    if (username.isEmpty || password.isEmpty) {
      _lastAuthError = 'Vui lòng điền đầy đủ thông tin';
      return false;
    }

    if (password.length < 8 || !passwordStrong.hasMatch(password)) {
      _lastAuthError = 'Mật khẩu phải có ít nhất 8 ký tự và chứa cả chữ và số';
      return false;
    }

    if (!emailReg.hasMatch(email)) {
      _lastAuthError = 'Email không hợp lệ';
      return false;
    }

    if (!phoneReg.hasMatch(phone)) {
      _lastAuthError = 'Số điện thoại không hợp lệ';
      return false;
    }

    try {
      final result = await _dbService.registerUser(
        username: username,
        password: password,
        email: email,
        phone: phone,
      );

      if (result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>;
        _isLoggedIn = true;
        _username = user['username'] as String;
        _userId = user['id'] as int;
        _userEmail = user['email'] as String?;
        _userPhone = user['phone'] as String?;
        _avatarUrl = user['avatar_url'] as String?;
        _fullName = user['fullName'] as String?;
        _walletBalance = (user['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        notifyListeners();
        return true;
      } else {
        _lastAuthError = result['message'] as String? ?? 'Đăng ký thất bại';
        return false;
      }
    } on SocketException catch (e) {
      _lastAuthError = 'Không thể kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.';
      if (kDebugMode) print('SocketException khi đăng ký: $e');
      return false;
    } catch (e) {
      _lastAuthError = 'Lỗi kết nối database: ${e.toString().split('\n').first}';
      if (kDebugMode) print('Register error: $e');
      return false;
    }
  }

  // Mock Google login
  Future<bool> loginWithGoogle() async {
    _lastAuthError = null;
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final account = await googleSignIn.signIn();
      if (account == null) return false; // user cancelled
      _isLoggedIn = true;
      _username = account.displayName ?? account.email;
      notifyListeners();
      return true;
    } catch (e) {
      _lastAuthError = e.toString();
      if (kDebugMode) print('Google sign-in error: $_lastAuthError');

      // If running on web and the error is due to missing client ID, try redirect flow
      if (kIsWeb) {
        final clientId = getMetaContent('google-client-id');
        final redirect = getMetaContent('oauth-redirect-uri');
        if (clientId != null && redirect != null) {
          final url = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
            'client_id': clientId,
            'redirect_uri': redirect,
            'response_type': 'token', // implicit flow for demo (consider PKCE for production)
            'scope': 'openid email profile',
            'prompt': 'select_account'
          }).toString();
          openUrlInNewTab(url);
          _lastAuthError = 'Opened Google sign-in page in a new tab.';
        }
      }
      return false;
    }
  }

  // Mock Facebook login
  Future<bool> loginWithFacebook() async {
    _lastAuthError = null;
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        _isLoggedIn = true;
        _username = userData['name'] ?? userData['email'] ?? 'facebook_user';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      if (kDebugMode) print('Facebook sign-in error: $_lastAuthError');
      if (kIsWeb) {
        final appId = getMetaContent('facebook-app-id');
        final redirect = getMetaContent('oauth-redirect-uri');
        if (appId != null && redirect != null) {
          final url = Uri.https('www.facebook.com', '/v16.0/dialog/oauth', {
            'client_id': appId,
            'redirect_uri': redirect,
            'state': 'fb_${DateTime.now().millisecondsSinceEpoch}',
            'scope': 'email,public_profile'
          }).toString();
          openUrlInNewTab(url);
          _lastAuthError = 'Opened Facebook sign-in page in a new tab.';
        }
      }
      return false;
    }
  }

  Future<bool> updateAvatar(String avatarUrl) async {
    if (_userId == null) return false;
    
    try {
      final result = await _dbService.updateUserAvatar(
        userId: _userId!,
        avatarUrl: avatarUrl,
      );
      
      if (result['success'] == true) {
        _avatarUrl = avatarUrl;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Update avatar error: $e');
      return false;
    }
  }

  /// Cập nhật thông tin cá nhân
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    if (_userId == null) return false;

    try {
      final result = await _dbService.updateUserProfile(
        userId: _userId!,
        fullName: fullName,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
      );

      if (result['success'] == true) {
        final user = result['user'] as Map<String, dynamic>?;
        if (user != null) {
          _userEmail = user['email'] as String?;
          _userPhone = user['phone'] as String?;
          _avatarUrl = user['avatar_url'] as String?;
          _fullName = user['fullName'] as String?;
          _walletBalance = (user['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        }
        notifyListeners();
        return true;
      }
      _lastAuthError = result['message'] as String?;
      return false;
    } catch (e) {
      _lastAuthError = 'Lỗi: $e';
      if (kDebugMode) print('Update profile error: $e');
      return false;
    }
  }

  /// Tải lại số dư ví
  Future<void> refreshWalletBalance() async {
    if (_userId == null) return;

    try {
      _walletBalance = await _dbService.getWalletBalance(_userId!);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Refresh wallet balance error: $e');
    }
  }

  void logout() {
    _isLoggedIn = false;
    _username = null;
    _userId = null;
    _userEmail = null;
    _userPhone = null;
    _avatarUrl = null;
    _fullName = null;
    _walletBalance = 0.0;
    notifyListeners();
  }
}
