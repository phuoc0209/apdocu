import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class CreateProductScreen extends StatefulWidget {
  final ProductModel? product; // For editing

  const CreateProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _addressController = TextEditingController();

  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  final NotificationService _notificationService = NotificationService();

  List<XFile> _selectedImages = [];
  ProductCategory _selectedCategory = ProductCategory.other;
  ProductCondition _selectedCondition = ProductCondition.usedLittle;
  Position? _currentPosition;
  String? _locationAddress;
  bool _isLoading = false;
  bool _useLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _titleController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description;
      _tagsController.text = widget.product!.tags.join(', ');
      _addressController.text = widget.product!.locationAddress ?? '';
      _selectedCategory = widget.product!.category;
      _selectedCondition = widget.product!.condition;
      _useLocation = widget.product!.location != null;
      _locationAddress = widget.product!.locationAddress;
    }
    _getUserLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _currentPosition = position;
        _locationAddress = address;
        if ((_addressController.text).trim().isEmpty && address != null) {
          _addressController.text = address;
        }
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && widget.product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất một ảnh')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('Starting save product...');
      final user = _authService.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final userData = await _authService.getUserData(user.uid);
      if (userData == null) throw Exception('Không tìm thấy thông tin người dùng');

      List<String> tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

        final manualAddress = _addressController.text.trim();
        final resolvedAddress = manualAddress.isNotEmpty
          ? manualAddress
          : (_useLocation ? _locationAddress : null);

      ProductModel product;
      
      if (widget.product == null) {
        print('Creating new product...');
        // Create new product
        product = ProductModel(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrls: [],
          category: _selectedCategory,
          condition: _selectedCondition,
          status: ProductStatus.pending,
          ownerId: user.uid,
          ownerName: userData.displayName,
          ownerPhotoURL: userData.photoURL,
          location: _useLocation && _currentPosition != null
              ? ProductLocation(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude)
              : null,
          locationAddress: resolvedAddress,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tags: tags,
        );

        print('Uploading images...');
        await _productService.createProduct(product, _selectedImages);
        print('Product created successfully');

        // Tạo thông báo chờ duyệt (lưu vào lịch sử)
        await _notificationService.addNotification(
          AppNotification(
            id: const Uuid().v4(),
            userId: user.uid,
            type: AppNotificationType.postPending,
            title: 'Bài đăng đang chờ duyệt',
            body:
                'Bài "${_titleController.text.trim()}" đã được gửi và sẽ được admin duyệt sớm.',
            relatedProductId: product.id,
            relatedUserId: null,
            createdAt: DateTime.now(),
          ),
        );
      } else {
        print('Updating existing product...');
        // Update existing product
        product = widget.product!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          condition: _selectedCondition,
          location: _useLocation && _currentPosition != null
              ? ProductLocation(latitude: _currentPosition!.latitude, longitude: _currentPosition!.longitude)
              : null,
          locationAddress: resolvedAddress,
          tags: tags,
        );

        await _productService.updateProduct(
          product,
          _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        print('Product updated successfully');
      }

      if (mounted) {
        // Toast nổi 3 giây ở trên cùng
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF4CAF50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.product == null
                        ? 'Đã đăng sản phẩm, chờ admin duyệt. Thông báo đã lưu trong mục Thông báo.'
                        : 'Đã cập nhật sản phẩm thành công.',
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error saving product: $e');
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final targetBodyWidth = maxWidth > 1200 ? 1000.0 : maxWidth * 0.9;
            final horizontalPadding = (maxWidth - targetBodyWidth) / 2;
            final resolvedPadding = horizontalPadding < 24 ? 24.0 : horizontalPadding;
            final bodyWidth = maxWidth - (resolvedPadding * 2);
            final innerWidth = bodyWidth - 64; // subtract card horizontal padding
            final columns = innerWidth >= 900
                ? 3
              : innerWidth >= 620
                    ? 2
                    : 1;
            const gap = 24.0;
            final singleFieldWidth = columns == 1
              ? innerWidth
              : (innerWidth - ((columns - 1) * gap)) / columns;

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
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: const Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Cập nhật sản phẩm' : 'Tạo sản phẩm mới',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E335A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isEditing
                                  ? 'Chỉnh sửa thông tin để cập nhật listing của bạn'
                                  : 'Điền thông tin chi tiết để đăng sản phẩm lên sàn',
                              style: const TextStyle(
                                color: Color(0xFF8389A8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 26,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF6C63FF),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Thông tin sản phẩm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E335A),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4E6F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: gap,
                            runSpacing: 20,
                            children: [
                              _buildLabeledField(
                                label: 'Tên sản phẩm',
                                width: singleFieldWidth,
                                child: TextFormField(
                                  controller: _titleController,
                                  decoration: _inputDecoration(hint: 'Nhập tên sản phẩm'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập tên sản phẩm';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              _buildLabeledField(
                                label: 'Danh mục',
                                width: singleFieldWidth,
                                child: DropdownButtonFormField<ProductCategory>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  decoration: _inputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: ProductCategory.homeAppliances,
                                      child: Text('Đồ gia dụng'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCategory.fashion,
                                      child: Text('Thời trang'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCategory.electronics,
                                      child: Text('Điện tử'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCategory.books,
                                      child: Text('Sách vở'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCategory.other,
                                      child: Text('Khác'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedCategory = value!);
                                  },
                                ),
                              ),
                              _buildLabeledField(
                                label: 'Tình trạng',
                                width: singleFieldWidth,
                                child: DropdownButtonFormField<ProductCondition>(
                                  value: _selectedCondition,
                                  isExpanded: true,
                                  decoration: _inputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: ProductCondition.new90to100,
                                      child: Text('Mới 90-100%'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCondition.usedLittle,
                                      child: Text('Dùng ít'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCondition.usedModerate,
                                      child: Text('Dùng vừa'),
                                    ),
                                    DropdownMenuItem(
                                      value: ProductCondition.usedMuch,
                                      child: Text('Dùng nhiều'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedCondition = value!);
                                  },
                                ),
                              ),
                              _buildLabeledField(
                                label: 'Tags',
                                width: singleFieldWidth,
                                child: TextFormField(
                                  controller: _tagsController,
                                  decoration: _inputDecoration(
                                    hint: 'Ví dụ: mới, chất lượng, giảm giá',
                                  ),
                                ),
                              ),
                              _buildLabeledField(
                                label: 'Địa chỉ',
                                width: singleFieldWidth,
                                child: TextFormField(
                                  controller: _addressController,
                                  decoration: _inputDecoration(
                                    hint:
                                        'Ví dụ: 123 Nguyễn Trãi, Quận 5, TP.HCM',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildLabeledField(
                            label: 'Mô tả sản phẩm',
                            width: double.infinity,
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              decoration: _inputDecoration(
                                hint: 'Chia sẻ chi tiết nổi bật, tình trạng và lợi ích sản phẩm',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mô tả';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Hình ảnh sản phẩm',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E335A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              ..._selectedImages.asMap().entries.map((entry) {
                                return _buildImagePreviewTile(entry.key, entry.value);
                              }),
                              _buildAddImageTile(),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE0E3FF)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Đính kèm vị trí',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E335A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _useLocation
                                            ? (_locationAddress ?? 'Đang lấy vị trí của bạn...')
                                            : (_addressController.text.trim().isNotEmpty
                                                ? _addressController.text.trim()
                                                : 'Cho phép định vị để tăng độ tin cậy cho listing'),
                                        style: const TextStyle(
                                          color: Color(0xFF8389A8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _useLocation,
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF6C63FF),
                                  onChanged: _currentPosition != null
                                      ? (value) {
                                          setState(() => _useLocation = value);
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Hãy đảm bảo thông tin chính xác để sản phẩm của bạn được duyệt nhanh chóng.',
                                  style: TextStyle(
                                    color: Color(0xFF9AA0C2),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 16,
                                  ),
                                  backgroundColor: const Color(0xFF6C63FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                label: Text(
                                  isEditing ? 'Cập nhật' : 'Tiếp tục',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildLabeledField({
    required String label,
    required Widget child,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4C4F6B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E3FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
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

  Widget _buildImagePreviewTile(int index, XFile imageFile) {
    return FutureBuilder<Uint8List>(
      future: imageFile.readAsBytes(),
      builder: (context, snapshot) {
        final placeholder = Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F1FF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );

        if (!snapshot.hasData) {
          return placeholder;
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                snapshot.data!,
                width: 128,
                height: 128,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAddImageTile() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E3FF), style: BorderStyle.solid),
          color: const Color(0xFFF7F7FF),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: Color(0xFF6C63FF), size: 28),
            SizedBox(height: 6),
            Text(
              'Thêm ảnh',
              style: TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
