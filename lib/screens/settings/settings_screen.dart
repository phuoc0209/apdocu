import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/theme_notifier.dart';
import '../../utils/language_provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../admin/user_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  bool _isDarkMode = false;
  String _selectedLanguage = 'vi';
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = _authService.currentUser;
    
    bool isAdmin = false;
    if (currentUser != null) {
      isAdmin = await _adminService.isAdmin(currentUser.uid);
    }
    
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'vi';
      _isAdmin = isAdmin;
      _isLoading = false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    await ThemeNotifier().setThemeMode(value);
    setState(() {
      _isDarkMode = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Đã bật chế độ tối' : 'Đã tắt chế độ tối'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _changeLanguage(String language) async {
    await LanguageProvider().setLanguage(language);
    setState(() {
      _selectedLanguage = language;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(language == 'vi' ? 'Đã chuyển sang Tiếng Việt' : 'Changed to English'),
          duration: const Duration(seconds: 1),
        ),
      );
      
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _changePassword(
                  currentPasswordController.text,
                  newPasswordController.text,
                );
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      // TODO: Implement change password via API
      // await _authService.changePassword(currentPassword, newPassword);
      
      // For now, just simulate success or failure based on logic
      // In a real app, this would be an API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tính năng đổi mật khẩu đang được cập nhật'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = LanguageProvider();
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleSpacing: 0,
        title: Text(
          lp.translate('settings'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildSettingsTile(
            icon: Icons.notifications_none,
            title: lp.translate('push_notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // TODO: Implement notification settings
              },
            ),
          ),
          _buildSettingsTile(
            icon: _isDarkMode ? Icons.dark_mode : Icons.light_mode,
            title: lp.translate('dark_mode'),
            onTap: () => _toggleDarkMode(!_isDarkMode),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: _selectedLanguage == 'vi'
                ? '${lp.translate('language')}: Tiếng Việt'
                : '${lp.translate('language')}: English',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(lp.translate('language_display')),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('🇻🇳 Tiếng Việt'),
                        value: 'vi',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          Navigator.pop(context);
                          if (value != null) _changeLanguage(value);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('🇬🇧 English'),
                        value: 'en',
                        groupValue: _selectedLanguage,
                        onChanged: (value) {
                          Navigator.pop(context);
                          if (value != null) _changeLanguage(value);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.lock_reset,
            title: lp.translate('change_password'),
            onTap: _showChangePasswordDialog,
          ),
          if (_isAdmin)
            _buildSettingsTile(
              icon: Icons.admin_panel_settings,
              title: lp.translate('user_management'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
              },
            ),
          const Divider(height: 24),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: '${lp.translate('version')} 1.0.0',
          ),
          _buildSettingsTile(
            icon: Icons.description_outlined,
            title: lp.translate('terms'),
            onTap: () {
              // TODO: Show terms
            },
          ),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: lp.translate('privacy'),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
