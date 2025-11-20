import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth.dart';
import '../widgets/auth_sheet.dart';
import '../widgets/rating_stars.dart';
import '../widgets/edit_profile_dialog.dart';
import '../screens/wallet_screen.dart';
import '../screens/favorites_screen.dart';
import '../services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) return;

    try {
      // Chọn ảnh từ gallery hoặc camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Lưu ảnh vào file system
      final imageService = ImageService.instance;
      final imageFile = File(image.path);
      final fileName = await imageService.saveImageFromFile(imageFile);

      if (fileName == null) {
        if (!mounted) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi lưu ảnh'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Upload lên database
      final success = await auth.updateAvatar(fileName);

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi cập nhật ảnh đại diện'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      // 🌈 Nền gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF74ABE2), Color(0xFF5563DE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🧍 Ảnh đại diện có viền và shadow
                GestureDetector(
                  onTap: auth.isLoggedIn ? _pickAndUploadImage : null,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x33000000),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: _buildAvatar(auth.avatarUrl),
                        ),
                      ),
                      if (auth.isLoggedIn)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 👤 Tên người dùng
                Text(
                  auth.isLoggedIn 
                      ? (auth.fullName ?? auth.username ?? 'Người dùng') 
                      : 'Khách chưa đăng nhập',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (auth.isLoggedIn && auth.userEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    auth.userEmail!,
                    style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14),
                  ),
                ],
                if (auth.isLoggedIn && auth.userPhone != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    auth.userPhone!,
                    style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 14),
                  ),
                ],

                const SizedBox(height: 24),
                if (auth.isLoggedIn) ...[
                  // Menu items
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x1A000000),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.account_balance_wallet, color: Color(0xFF6C63FF)),
                          title: const Text('Ví của tôi'),
                          subtitle: Text(
                            '${auth.walletBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const WalletScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.favorite, color: Color(0xFF6C63FF)),
                          title: const Text('Sản phẩm yêu thích'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                          title: const Text('Chỉnh sửa thông tin'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => const EditProfileDialog(),
                            ).then((updated) {
                              if (updated == true) {
                                setState(() {});
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                    // Reputation area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Độ tin cậy', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                              SizedBox(height: 6),
                              Text('Người bán tích lũy điểm uy tín từ đánh giá'),
                            ],
                          ),
                          // Rating widget
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: RatingStars(
                              initial: 4.2,
                              onRate: (r) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cảm ơn bạn đã đánh giá: $r')));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 🔘 Nút đăng xuất đẹp
                  ElevatedButton.icon(
                    onPressed: () => auth.logout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      elevation: 6,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất', style: TextStyle(fontSize: 16)),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(
                    'Đăng nhập để truy cập nhiều tính năng hơn 💡',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),

                  // 🌟 Nút đăng ký/đăng nhập hiện đại
                  ElevatedButton(
                    onPressed: () async {
                      bool? res;
                      if (kIsWeb) {
                        res = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: SizedBox(
                              width: 600,
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: const AuthSheet(),
                            ),
                          ),
                        );
                      } else {
                        res = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => const AuthSheet(),
                        );
                      }
                      if (context.mounted && res == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đăng nhập/Đăng ký thành công')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      elevation: 6,
                    ),
                    child: const Text('Đăng ký / Đăng nhập', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white24,
        child: Icon(Icons.person, size: 50, color: Colors.white70),
      );
    }

    // Nếu là tên file từ ImageService
    if (!avatarUrl.contains('/') && !avatarUrl.startsWith('http') && !avatarUrl.startsWith('data:')) {
      return FutureBuilder<File?>(
        future: ImageService.instance.getImageFile(avatarUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: FileImage(snapshot.data!),
              backgroundColor: Colors.white24,
            );
          }
          return const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: CircularProgressIndicator(color: Colors.white70),
          );
        },
      );
    }

    // Base64 image (tương thích với dữ liệu cũ)
    if (avatarUrl.startsWith('data:image')) {
      try {
        final base64String = avatarUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(bytes),
          backgroundColor: Colors.white24,
        );
      } catch (e) {
        return const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white24,
          child: Icon(Icons.person, size: 50, color: Colors.white70),
        );
      }
    }

    // Network image
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.white24,
      );
    }

    // Local file path
    if (avatarUrl.startsWith('/')) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(avatarUrl)),
        backgroundColor: Colors.white24,
      );
    }

    return const CircleAvatar(
      radius: 50,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, size: 50, color: Colors.white70),
    );
  }
}
