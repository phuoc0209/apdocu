import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../utils/language_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService();
  final AuthService _authService = AuthService();
  final LanguageProvider _lang = LanguageProvider();
  bool _isCurrentUserAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final isAdmin = await _adminService.isAdmin(currentUser.uid);
      setState(() => _isCurrentUserAdmin = isAdmin);
      
      if (!isAdmin) {
        // Không phải admin, quay lại
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_lang.translate('no_permission'))),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCurrentUserAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E335A),
        centerTitle: true,
        title: Text(
          _lang.translate('manage_users'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _adminService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrentUser =
                  user.uid == _authService.currentUser?.uid;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E335A),
                          ),
                        ),
                      ),
                      if (user.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _lang.translate('admin_badge'),
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B6F8D),
                        ),
                      ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            user.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA0C2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: isCurrentUser
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'toggle_admin') {
                              await _toggleAdmin(user);
                            } else if (value == 'ban') {
                              await _banUser(user);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle_admin',
                              child: Row(
                                children: [
                                  Icon(
                                    user.isAdmin
                                        ? Icons.remove_moderator
                                        : Icons.admin_panel_settings,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user.isAdmin
                                      ? 'Gỡ admin'
                                      : 'Đặt làm admin'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'ban',
                              child: Row(
                                children: [
                                  Icon(Icons.block,
                                      size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Khóa tài khoản'),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleAdmin(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isAdmin ? 'Gỡ quyền admin' : 'Cấp quyền admin'),
        content: Text(
          user.isAdmin
              ? 'Gỡ quyền admin cho ${user.displayName}?'
              : 'Cấp quyền admin cho ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.setAdmin(user.uid, !user.isAdmin);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(user.isAdmin ? 'Đã gỡ quyền admin' : 'Đã cấp quyền admin'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _banUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khóa tài khoản'),
        content: Text('Khóa tài khoản ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Khóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.banUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã khóa tài khoản'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
