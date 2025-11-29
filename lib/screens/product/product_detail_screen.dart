import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../models/comment_model.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  int _quantity = 1;
  
  ProductModel? _product;
  bool _isLoading = true;
  bool _isFollowing = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final product = await _productService.getProduct(widget.productId);
    if (!mounted) return;

    setState(() {
      _product = product;
      _isLoading = false;
      _currentImageIndex = 0;
    });

    if (product != null) {
      await _productService.incrementViewCount(widget.productId);
      await _checkFollowing(product);
    }
  }

  Future<void> _checkFollowing(ProductModel product) async {
    if (_currentUser == null) return;

    final isFollowing = await _authService.isFollowing(
      _currentUser!.uid,
      product.ownerId,
    );

    if (!mounted) return;
    setState(() {
      _isFollowing = isFollowing;
    });
  }

  Future<void> _toggleFollow() async {
    if (_currentUser == null || _product == null) return;

    try {
      await _authService.toggleFollow(_currentUser!.uid, _product!.ownerId);
      setState(() {
        _isFollowing = !_isFollowing;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'Đã theo dõi' : 'Đã bỏ theo dõi'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _startChat() async {
    if (_currentUser == null || _product == null) return;

    try {
      final currentUserData = await _authService.getUserData(_currentUser!.uid);
      if (currentUserData == null) return;

      final chatId = await _chatService.createOrGetChat(
        _currentUser!.uid,
        currentUserData.displayName,
        currentUserData.photoURL,
        _product!.ownerId,
        _product!.ownerName,
        _product!.ownerPhotoURL,
      );

      if (mounted) {
        Navigator.pushNamed(context, '/chat-detail', arguments: chatId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_currentUser == null || _commentController.text.trim().isEmpty) return;

    try {
      final userData = await _authService.getUserData(_currentUser!.uid);
      if (userData == null) return;

      final comment = CommentModel(
        id: const Uuid().v4(),
        productId: widget.productId,
        userId: _currentUser!.uid,
        userName: userData.displayName,
        userPhotoURL: userData.photoURL,
        content: _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _productService.addComment(comment);
      _commentController.clear();
      
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _markAsSoldOut() async {
    if (_product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đánh dấu Sold Out'),
        content: const Text('Xác nhận sản phẩm đã được trao đổi?'),
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

    if (confirmed == true) {
      try {
        await _productService.markAsSoldOut(widget.productId);
        _loadProduct();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã đánh dấu sold out')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: const Text('Bạn có chắc muốn xóa sản phẩm này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _productService.deleteProduct(widget.productId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa sản phẩm'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Go back to previous screen
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
  }

  void _openFullScreenGallery(int initialIndex) {
    if (_product == null || _product!.imageUrls.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageGallery(
            images: _product!.imageUrls,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy sản phẩm')),
      );
    }

    final String ownerId = _product!.ownerId.trim();
    final String? currentUid = _currentUser?.uid;
    final String? currentEmail = _currentUser?.email?.trim();

    // Some legacy/sample products may have stored owner as email instead of uid.
    // Consider owner if current user's uid or email matches the stored ownerId.
    final isOwner = currentUid != null && (
      currentUid == ownerId || (currentEmail != null && currentEmail == ownerId)
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isOwner),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      children: [
                        _buildImageGallery(),
                        Transform.translate(
                          offset: const Offset(0, -32),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildDetailCard(isOwner),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isOwner && _product!.status == ProductStatus.approved)
            _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isOwner) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          _buildCircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _buildCircleIconButton(
            icon: Icons.share_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng chia sẻ sẽ sớm có mặt.')),
              );
            },
          ),
          const SizedBox(width: 12),
          if (isOwner)
            _buildOwnerMenuButton()
          else
            _buildCircleIconButton(
              icon: Icons.bookmark_border_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hãy theo dõi chủ sản phẩm để cập nhật nhanh nhất!')),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOwnerMenuButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: PopupMenuButton(
        icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6C63FF)),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Chỉnh sửa'),
          ),
          if (_product!.status == ProductStatus.approved)
            const PopupMenuItem(
              value: 'soldout',
              child: Text('Đánh dấu sold out'),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Xóa'),
          ),
        ],
        onSelected: (value) async {
          if (value == 'edit') {
            final result = await Navigator.pushNamed(
              context,
              '/edit-product',
              arguments: _product,
            );
            if (result == true) {
              _loadProduct();
            }
          } else if (value == 'soldout') {
            _markAsSoldOut();
          } else if (value == 'delete') {
            _deleteProduct();
          }
        },
      ),
    );
  }

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF6C63FF)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _product!.imageUrls;
    final hasImages = images.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEFEA), Color(0xFFFFF6F3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemCount: hasImages ? images.length : 1,
              itemBuilder: (context, index) {
                if (!hasImages) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: Color(0xFFB0B5D5),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => _openFullScreenGallery(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: CachedNetworkImage(
                      imageUrl: images[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFE1E5F8),
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9AA0C2), size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              hasImages ? images.length : 1,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentImageIndex == index ? 20 : 8,
                decoration: BoxDecoration(
                  color: _currentImageIndex == index
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF6C63FF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(bool isOwner) {
    final product = _product!;

    return DefaultTabController(
      length: 3,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E335A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRatingRow(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.category_outlined, product.categoryDisplayName),
                          _buildInfoChip(Icons.inventory_2_outlined, product.conditionDisplayName),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildQuantityStepper(),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  '${product.viewCount} lượt xem',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(product.statusDisplayName),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: Color(0xFF6C63FF), width: 3),
                  insets: EdgeInsets.symmetric(horizontal: 28),
                ),
                labelColor: Color(0xFF2E335A),
                unselectedLabelColor: Color(0xFF9AA0C2),
                labelStyle: TextStyle(fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: 'Description'),
                  Tab(text: 'Review'),
                  Tab(text: 'Same products'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 320,
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildDescriptionTab(product),
                  _buildReviewsTab(isOwner),
                  _buildSameProductsTab(),
                ],
              ),
            ),
            _buildOwnerSection(isOwner),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        ...List.generate(
          4,
          (index) => const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFC107)),
        ),
        const Icon(Icons.star_half_rounded, size: 18, color: Color(0xFFFFC107)),
        const SizedBox(width: 8),
        Text(
          '${_product!.viewCount} lượt xem',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF8389A8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStepperButton(
            icon: Icons.remove,
            onPressed: () {
              if (_quantity == 1) return;
              setState(() => _quantity--);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E335A),
              ),
            ),
          ),
          _buildStepperButton(
            icon: Icons.add,
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF6C63FF)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDescriptionTab(ProductModel product) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chi tiết',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E335A),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailLine('Danh mục', product.categoryDisplayName),
          _buildDetailLine('Tình trạng', product.conditionDisplayName),
          if (product.tags.isNotEmpty)
            _buildDetailLine('Tags', product.tags.map((e) => '#$e').join('   ')),
          const SizedBox(height: 20),
          Text(
            product.description,
            style: const TextStyle(color: Color(0xFF4C4F6B), height: 1.5),
          ),
          if (product.locationAddress != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Địa điểm',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E335A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.locationAddress!,
                    style: const TextStyle(color: Color(0xFF4C4F6B)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8389A8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF4C4F6B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(bool isOwner) {
    return StreamBuilder<List<CommentModel>>(
      stream: _productService.getProductComments(widget.productId),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comments.isEmpty)
                const Text(
                  'Chưa có bình luận nào. Hãy là người đầu tiên chia sẻ cảm nhận của bạn!',
                  style: TextStyle(color: Color(0xFF8389A8)),
                )
              else
                ...comments.map(
                  (comment) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: comment.userPhotoURL != null
                              ? CachedNetworkImageProvider(comment.userPhotoURL!)
                              : null,
                          child: comment.userPhotoURL == null
                              ? const Icon(Icons.person, color: Color(0xFF6C63FF))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E335A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                style: const TextStyle(color: Color(0xFF4C4F6B)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                timeago.format(comment.createdAt, locale: 'vi'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9AA0C2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!isOwner && _product!.status == ProductStatus.approved)
                _buildCommentComposer(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentComposer() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Viết bình luận...',
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF6C63FF),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _addComment,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSameProductsTab() {
    final tags = _product!.tags;

    if (tags.isEmpty) {
      return const Center(
        child: Text(
          'Chúng tôi sẽ gợi ý thêm sản phẩm tương tự trong thời gian tới.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8389A8)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(right: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildOwnerSection(bool isOwner) {
    final product = _product!;

    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: product.ownerPhotoURL != null
                ? CachedNetworkImageProvider(product.ownerPhotoURL!)
                : null,
            child: product.ownerPhotoURL == null
                ? const Icon(Icons.person, color: Color(0xFF6C63FF), size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.ownerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E335A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đăng ngày ${DateFormat('dd/MM/yyyy').format(product.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF8389A8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Chủ sở hữu',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _toggleFollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? const Color(0xFFEDEAFF) : const Color(0xFF6C63FF),
                foregroundColor: _isFollowing ? const Color(0xFF6C63FF) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label) {
    Color background;
    Color textColor;

    switch (_product!.status) {
      case ProductStatus.pending:
        background = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFF57C00);
        break;
      case ProductStatus.approved:
        background = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case ProductStatus.rejected:
        background = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      case ProductStatus.soldOut:
        background = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        color: Colors.transparent,
        child: SizedBox(
          height: 58,
          child: ElevatedButton(
            onPressed: _startChat,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 6,
              shadowColor: const Color(0xFF6C63FF).withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded),
                const SizedBox(width: 10),
                Text('Nhắn tin với ${_product!.ownerName.split(' ').first}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageGallery({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<_FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: widget.images[index],
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentIndex == index ? 18 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

