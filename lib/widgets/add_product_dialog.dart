import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/products.dart';
import '../providers/auth.dart';
import '../services/image_service.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _exchangeValueCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImages = []; // Lưu tên file ảnh (ví dụ: "img_123.jpg")
  final ImageService _imageService = ImageService.instance;
  final _sellerNameCtrl = TextEditingController();
  final _sellerPhoneCtrl = TextEditingController();
  final _sellerEmailCtrl = TextEditingController();
  String _selectedCategory = 'Khác';
  String _selectedExchangeType = 'sell';
  bool _loading = false;
  
  static const int maxImages = 10;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _animController.forward();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _conditionCtrl.dispose();
    _sizeCtrl.dispose();
    _reasonCtrl.dispose();
    _exchangeValueCtrl.dispose();
    _sellerNameCtrl.dispose();
    _sellerPhoneCtrl.dispose();
    _sellerEmailCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    
    if (_selectedImages.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tối đa $maxImages ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        // Lưu ảnh vào file system và lấy tên file
        final imageFile = File(image.path);
        
        if (!await imageFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File ảnh không tồn tại'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final fileName = await _imageService.saveImageFromFile(imageFile);
        
        if (fileName != null && mounted) {
          // Kiểm tra lại file đã được lưu chưa
          final savedFile = await _imageService.getImageFile(fileName);
          if (savedFile != null) {
            setState(() {
              _selectedImages.add(fileName);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm ảnh: ${fileName.substring(0, 20)}...'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lỗi: Ảnh không được lưu đúng'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi lưu ảnh vào file system'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tối đa $maxImages ảnh'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final imageFile = File(image.path);
        final fileName = await _imageService.saveImageFromFile(imageFile);
        if (fileName != null && mounted) {
          setState(() => _selectedImages.add(fileName));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chụp ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Kiểm tra đăng nhập
    if (!authProvider.isLoggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đăng sản phẩm'),
          backgroundColor: Colors.orange,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    
    if (!mounted) return;
    setState(() => _loading = true);
    
    if (!mounted) return;
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0;
    
    if (price <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá phải lớn hơn 0'), backgroundColor: Colors.red),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    // Nếu không có ảnh nào, tạo ảnh placeholder base64 (1x1 transparent)
    // Hoặc có thể để trống và hiển thị placeholder trong UI
    final finalImageUrls = _selectedImages.isEmpty
        ? <String>[] // Để trống, UI sẽ hiển thị placeholder
        : _selectedImages;

    final success = await productsProvider.addProduct(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: price,
      imageUrls: finalImageUrls,
      category: _selectedCategory,
      sellerId: authProvider.userId,
      sellerName: _sellerNameCtrl.text.trim().isEmpty 
          ? authProvider.username 
          : _sellerNameCtrl.text.trim(),
      sellerPhone: _sellerPhoneCtrl.text.trim().isEmpty 
          ? authProvider.userPhone 
          : _sellerPhoneCtrl.text.trim(),
      sellerEmail: _sellerEmailCtrl.text.trim().isEmpty 
          ? authProvider.userEmail 
          : _sellerEmailCtrl.text.trim(),
      itemCondition: _conditionCtrl.text.trim().isEmpty ? null : _conditionCtrl.text.trim(),
      itemSize: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
      exchangeReason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      exchangeValue: double.tryParse(_exchangeValueCtrl.text.replaceAll(',', '')),
      exchangeType: _selectedExchangeType,
    );
    
    // Kiểm tra mounted sau async operation
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productsProvider.errorMessage ?? 'Lỗi khi thêm sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              elevation: 10,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Thêm sản phẩm',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C63FF),
                            ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Mô tả',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mô tả' : null,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Danh mục',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ProductsProvider.categories
                            .where((c) => c != 'Tất cả')
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                      // Tình trạng & kích thước
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _conditionCtrl,
                              decoration: InputDecoration(
                                labelText: 'Tình trạng',
                                hintText: 'Ví dụ: Mới, Cũ, Like new',
                                prefixIcon: const Icon(Icons.info_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sizeCtrl,
                              decoration: InputDecoration(
                                labelText: 'Kích thước',
                                hintText: 'Ví dụ: L, 40x30cm',
                                prefixIcon: const Icon(Icons.straighten),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonCtrl,
                        decoration: InputDecoration(
                          labelText: 'Lý do trao đổi',
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _exchangeValueCtrl,
                              decoration: InputDecoration(
                                labelText: 'Giá trị quy đổi (nếu có, VNĐ)',
                                prefixIcon: const Icon(Icons.price_check),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedExchangeType,
                              decoration: InputDecoration(
                                labelText: 'Hình thức',
                                prefixIcon: const Icon(Icons.swap_horiz),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'swap', child: Text('Đổi đồ')),
                                DropdownMenuItem(value: 'donate', child: Text('Tặng')),
                                DropdownMenuItem(value: 'sell', child: Text('Bán rẻ')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedExchangeType = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        decoration: InputDecoration(
                          labelText: 'Giá (VNĐ)',
                          hintText: 'Ví dụ: 100000',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Nhập giá sản phẩm';
                          final price = double.tryParse(v.replaceAll(',', ''));
                          if (price == null || price <= 0) return 'Giá phải lớn hơn 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Phần chọn ảnh
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hình ảnh sản phẩm (${_selectedImages.length}/$maxImages)',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          Row(
                            children: [
                              if (_selectedImages.length < maxImages)
                                ElevatedButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.photo_library, size: 18),
                                  label: const Text('Chọn ảnh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              if (_selectedImages.length < maxImages)
                                OutlinedButton.icon(
                                  onPressed: _takePhoto,
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('Chụp ảnh'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Hiển thị ảnh đã chọn
                      if (_selectedImages.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có ảnh nào',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Nhấn "Chọn ảnh" để thêm ảnh sản phẩm',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _getImageWidget(_selectedImages[index]),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          iconSize: 16,
                                          icon: const Icon(Icons.close, color: Colors.white),
                                          onPressed: () => _removeImage(index),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Thông tin người bán (tùy chọn)
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Thông tin người bán (tùy chọn)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sellerNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tên người bán',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Để trống sẽ dùng tên tài khoản',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sellerPhoneCtrl,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Để trống sẽ dùng SĐT tài khoản',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sellerEmailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Để trống sẽ dùng email tài khoản',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      // Nút submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Đăng sản phẩm',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getImageWidget(String fileName) {
    // fileName là tên file (ví dụ: "img_123.jpg")
    // Cần đọc từ ImageService
    return FutureBuilder<File?>(
      future: _imageService.getImageFile(fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Lỗi hiển thị ảnh preview: $fileName - $error');
              return const Icon(Icons.error, color: Colors.red);
            },
          );
        }
        debugPrint('❌ Không tìm thấy ảnh preview: $fileName');
        return const Icon(Icons.image_not_supported, color: Colors.grey);
      },
    );
  }
}
