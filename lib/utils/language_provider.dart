import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static final LanguageProvider _instance = LanguageProvider._internal();
  factory LanguageProvider() => _instance;
  LanguageProvider._internal();

  String _currentLanguage = 'vi';
  String get currentLanguage => _currentLanguage;

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'vi';
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    notifyListeners();
  }

  // Translations
  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'vi': {
      // Common
      'app_name': 'Trao Đổi Đồ Cũ',
      'home': 'Trang chủ',
      'search': 'Tìm kiếm',
      'products': 'Sản phẩm',
      'messages': 'Nhắn tin',
      'account': 'Tài khoản',
      'save': 'Lưu',
      'cancel': 'Hủy',
      'delete': 'Xóa',
      'edit': 'Sửa',
      'confirm': 'Xác nhận',
      'loading': 'Đang tải...',
      'error': 'Lỗi',
      'success': 'Thành công',
      
      // Home
      'search_placeholder': 'Bạn muốn tìm món đồ gì?',
      'categories': 'Danh mục',
      'no_products': 'Chưa có sản phẩm nào',
      
      // Categories
      'cat_fashion': 'Thời trang',
      'cat_electronics': 'Điện tử',
      'cat_books': 'Sách',
      'cat_home': 'Gia dụng',
      'cat_kids': 'Đồ trẻ em',
      'cat_entertainment': 'Giải trí',
      
      // Account
      'profile': 'Hồ sơ',
      'edit_profile': 'Chỉnh sửa hồ sơ',
      'settings': 'Cài đặt',
      'help': 'Trợ giúp',
      'about': 'Giới thiệu',
      'logout': 'Đăng xuất',
      'logout_confirm': 'Bạn có chắc muốn đăng xuất?',
      
      // Settings
      'appearance': 'Giao diện',
      'dark_mode': 'Chế độ tối',
      'language': 'Ngôn ngữ',
      'language_display': 'Ngôn ngữ hiển thị',
      'security': 'Bảo mật',
      'change_password': 'Đổi mật khẩu',
      'notifications': 'Thông báo',
      'push_notifications': 'Thông báo đẩy',
      'version': 'Phiên bản',
      'terms': 'Điều khoản sử dụng',
      'privacy': 'Chính sách bảo mật',
      
      // Admin
      'admin_panel': 'Quản trị',
      'user_management': 'Quản lý người dùng',
      'set_admin': 'Đặt làm admin',
      'remove_admin': 'Gỡ admin',
      'ban_user': 'Khóa tài khoản',
      
      // User Management
      'manage_users': 'Quản lý người dùng',
      'admin_badge': 'ADMIN',
      'no_permission': 'Bạn không có quyền truy cập',
      'grant_admin': 'Cấp quyền admin',
      'revoke_admin': 'Gỡ quyền admin',
      'ban_account': 'Khóa tài khoản',
      'admin_granted': 'Đã cấp quyền admin',
      'admin_revoked': 'Đã gỡ quyền admin',
      'account_banned': 'Đã khóa tài khoản',
    },
    'en': {
      // Common
      'app_name': 'Exchange Used Items',
      'home': 'Home',
      'search': 'Search',
      'products': 'Products',
      'messages': 'Messages',
      'account': 'Account',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'confirm': 'Confirm',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      
      // Home
      'search_placeholder': 'What are you looking for?',
      'categories': 'Categories',
      'no_products': 'No products yet',
      
      // Categories
      'cat_fashion': 'Fashion',
      'cat_electronics': 'Electronics',
      'cat_books': 'Books',
      'cat_home': 'Home Appliances',
      'cat_kids': 'Kids Items',
      'cat_entertainment': 'Entertainment',
      
      // Account
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'settings': 'Settings',
      'help': 'Help',
      'about': 'About',
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      
      // Settings
      'appearance': 'Appearance',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'language_display': 'Display Language',
      'security': 'Security',
      'change_password': 'Change Password',
      'notifications': 'Notifications',
      'push_notifications': 'Push Notifications',
      'version': 'Version',
      'terms': 'Terms of Service',
      'privacy': 'Privacy Policy',
      
      // Admin
      'admin_panel': 'Admin Panel',
      'user_management': 'User Management',
      'set_admin': 'Set as Admin',
      'remove_admin': 'Remove Admin',
      'ban_user': 'Ban Account',
      
      // User Management
      'manage_users': 'Manage Users',
      'admin_badge': 'ADMIN',
      'no_permission': 'You do not have permission',
      'grant_admin': 'Grant Admin Rights',
      'revoke_admin': 'Revoke Admin Rights',
      'ban_account': 'Ban Account',
      'admin_granted': 'Admin rights granted',
      'admin_revoked': 'Admin rights revoked',
      'account_banned': 'Account banned',
    },
  };
}
