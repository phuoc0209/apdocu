import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_image_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final AuthService _authService = AuthService();
  final FirestoreImageService _imageService = FirestoreImageService();
  final ImagePicker _picker = ImagePicker();
  
  User? _currentUser;
  UserModel? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  XFile? _selectedImage;
  String? _currentPhotoURL;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      final data = await _authService.getUserData(_currentUser!.uid);
      
      // Load profile image from Firestore
      String? photoURL;
      try {
        photoURL = await _imageService.getProfileImage(_currentUser!.uid);
      } catch (e) {
        print('Error loading profile image: $e');
      }
      
      setState(() {
        _userData = data;
        _displayNameController.text = data?.displayName ?? '';
        _bioController.text = data?.bio ?? '';
        _phoneController.text = data?.phoneNumber ?? '';
        _currentPhotoURL = photoURL;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _currentPhotoURL;

    try {
      print('Starting profile image upload to Firestore...');
      
      // Upload and save to Firestore (returns base64 data URL)
      await _imageService.uploadProfileImage(
        _selectedImage!,
        _currentUser!.uid,
      );
      
      print('Profile image saved successfully to Firestore');
      
      final refreshedPhoto = await _imageService.getProfileImage(_currentUser!.uid);
      setState(() {
        _currentPhotoURL = refreshedPhoto;
      });

      return refreshedPhoto;
    } catch (e) {
      print('Upload profile image error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh lên: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return _currentPhotoURL;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload image if selected (saves to Firestore separately)
      if (_selectedImage != null) {
        await _uploadProfileImage();
        if (mounted) {
          setState(() => _selectedImage = null);
        } else {
          _selectedImage = null;
        }
      }

      // Update user data (WITHOUT photoURL - it's stored separately)
      final updatedUser = _userData!.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        // DON'T update photoURL here - it's too long for Firestore field
      );

      await _authService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật hồ sơ thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Save profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null || _userData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
        body: const Center(
          child: Text('Vui lòng đăng nhập'),
        ),
      );
    }

    final Uint8List? photoBytes =
        _currentPhotoURL != null ? _decodeDataUrl(_currentPhotoURL!) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final targetWidth = maxWidth > 1000 ? 760.0 : maxWidth * 0.92;
            final horizontalPadding = (maxWidth - targetWidth) / 2;
            final resolvedPadding = horizontalPadding < 20 ? 20.0 : horizontalPadding;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                resolvedPadding,
                24,
                resolvedPadding,
                32,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: const Color(0xFF6C63FF),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Chỉnh sửa hồ sơ',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E335A),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Cập nhật thông tin cá nhân và liên hệ',
                              style: TextStyle(
                                color: Color(0xFF8389A8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6C63FF),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'Lưu',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: _buildAvatarSection(photoBytes),
                          ),
                          const SizedBox(height: 32),
                          LayoutBuilder(
                            builder: (context, innerConstraints) {
                              final innerWidth = innerConstraints.maxWidth;
                              final isLarge = innerWidth >= 640;
                              final fieldWidth = isLarge
                                  ? (innerWidth - 24) / 2
                                  : innerWidth;

                              return Wrap(
                                spacing: 24,
                                runSpacing: 20,
                                children: [
                                  _buildLabeledField(
                                    title: 'Tên hiển thị',
                                    width: fieldWidth,
                                    child: TextFormField(
                                      controller: _displayNameController,
                                      textCapitalization: TextCapitalization.words,
                                      decoration: _inputDecoration(
                                        hint: 'Ví dụ: Nguyễn Văn A',
                                        prefixIcon: Icons.person_outline,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Vui lòng nhập tên hiển thị';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _buildLabeledField(
                                    title: 'Số điện thoại',
                                    width: fieldWidth,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: _inputDecoration(
                                        hint: 'Không bắt buộc',
                                        prefixIcon: Icons.phone_outlined,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildLabeledField(
                            title: 'Giới thiệu bản thân',
                            child: TextFormField(
                              controller: _bioController,
                              maxLines: 4,
                              maxLength: 150,
                              decoration: _inputDecoration(
                                hint: 'Chia sẻ vài điều về bạn... (tối đa 150 ký tự)',
                                prefixIcon: Icons.chat_bubble_outline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLabeledField(
                            title: 'Email',
                            child: TextFormField(
                              initialValue: _userData!.email,
                              enabled: false,
                              decoration: _inputDecoration(
                                prefixIcon: Icons.alternate_email,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF0FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF6C63FF),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ảnh đại diện được lưu riêng để tối ưu dung lượng. Thay đổi ảnh sẽ được áp dụng ngay sau khi lưu.',
                              style: TextStyle(
                                color: Color(0xFF4C4F6B),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarSection(Uint8List? photoBytes) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF836FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? FutureBuilder<Uint8List>(
                          future: _selectedImage!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            }
                            return _buildAvatarPlaceholder();
                          },
                        )
                      : (photoBytes != null
                          ? Image.memory(photoBytes, fit: BoxFit.cover)
                          : _buildAvatarPlaceholder()),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Material(
                color: const Color(0xFF6C63FF),
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 20),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Chọn ảnh mới để làm nổi bật hồ sơ của bạn',
          style: TextStyle(
            color: Color(0xFF8389A8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: const Color(0xFFE7E8F8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_outline,
        size: 48,
        color: Color(0xFF6C63FF),
      ),
    );
  }

  Widget _buildLabeledField({
    required String title,
    required Widget child,
    double? width,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF4C4F6B),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }
    return content;
  }

  InputDecoration _inputDecoration({
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: const Color(0xFF6C63FF))
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E3FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E3FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
    );
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    if (!dataUrl.startsWith('data:image')) {
      return null;
    }

    try {
      final parts = dataUrl.split(',');
      if (parts.length < 2) return null;
      return base64Decode(parts.last);
    } catch (e) {
      debugPrint('Decode profile image error: $e');
      return null;
    }
  }
}
