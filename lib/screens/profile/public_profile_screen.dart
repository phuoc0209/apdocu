import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/seller_review_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/seller_review_service.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final SellerReviewService _sellerReviewService = SellerReviewService();
  final NotificationService _notificationService = NotificationService();

  UserModel? _user;
  List<ProductModel> _products = [];
  Map<ProductCategory, List<ProductModel>> _groupedProducts = {};
  int _totalViews = 0;
  bool _isLoading = true;
  double _averageRating = 0.0;
  int _ratingCount = 0;
  List<SellerReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getUserData(widget.userId);
      final products = await _productService.getUserProducts(widget.userId);

      final grouped = <ProductCategory, List<ProductModel>>{};
      int views = 0;
      for (final p in products) {
        grouped.putIfAbsent(p.category, () => []).add(p);
        views += p.viewCount;
      }

      final ratingSummary = await _sellerReviewService.getSellerRatingSummary(widget.userId);
      final reviews = await _sellerReviewService.getReviewsForSeller(widget.userId);

      if (!mounted) return;
      setState(() {
        _user = user;
        _products = products;
        _groupedProducts = grouped;
        _totalViews = views;
        _averageRating = ratingSummary['average'] is int 
            ? (ratingSummary['average'] as int).toDouble() 
            : (ratingSummary['average'] as double? ?? 0.0);
        _ratingCount = ratingSummary['count'] as int? ?? 0;
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy người dùng')),
      );
    }

    final isCurrentUser = _authService.currentUser?.uid == _user!.uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FB),
        body: SafeArea(
          child: Column(
            children: [
              _buildProfileHeader(isCurrentUser),
              const SizedBox(height: 16),
              _buildTabBar(),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildOverviewTab(),
                    _buildProductsTab(),
                    _buildReviewTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProfileHeader(bool isCurrentUser) {
    final joinDate = DateFormat('dd/MM/yyyy').format(_user!.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3FF),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              Positioned(
                bottom: -30,
                left: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 36,
                    backgroundImage: _user!.photoURL != null && _user!.photoURL!.isNotEmpty
                        ? CachedNetworkImageProvider(_user!.photoURL!)
                        : null,
                    child: (_user!.photoURL == null || _user!.photoURL!.isEmpty)
                        ? Text(
                            _user!.displayName.isNotEmpty
                                ? _user!.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6C63FF),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                top: -8,
                left: -8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF6C63FF)),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            _user!.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF2E335A),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildTagChip(_user!.isAdmin ? 'Admin' : 'Thành viên'),
              if (_products.isNotEmpty)
                _buildTagChip('${_products.length} sản phẩm'),
              _buildTagChip('Tham gia: $joinDate'),
              if (isCurrentUser)
                _buildTagChip('Tài khoản của bạn'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF6C63FF)),
              const SizedBox(width: 6),
              Text(
                _user!.email,
                style: const TextStyle(color: Color(0xFF4C4F6B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6C63FF),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const TabBar(
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFF6C63FF), width: 3),
          insets: EdgeInsets.symmetric(horizontal: 30),
        ),
        labelColor: Color(0xFF2E335A),
        unselectedLabelColor: Color(0xFF9AA0C2),
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Sản phẩm'),
          Tab(text: 'Đánh giá'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard(Icons.inventory_2_outlined, 'Sản phẩm', '${_products.length}'),
              _buildMetricCard(Icons.visibility_rounded, 'Lượt xem', '$_totalViews'),
              _buildMetricCard(Icons.people_outline, 'Người theo dõi', '${_user!.followers.length}'),
            ],
          ),
          const SizedBox(height: 28),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Người dùng này chưa có sản phẩm nào đang hiển thị.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8389A8)),
          ),
        ),
      );
    }

    final sections = _groupedProducts.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          for (final entry in sections) ...[
            _buildProductSection(entry.key, entry.value),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    final currentUser = _authService.currentUser;
    final isOwner = currentUser?.uid == _user!.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummaryCard(),
          const SizedBox(height: 24),
          if (!isOwner && currentUser != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () => _showAddReviewSheet(currentUser.uid),
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Viết đánh giá về người bán'),
              ),
            ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Chưa có đánh giá nào cho người bán này. Hãy là người đầu tiên để lại đánh giá sau khi giao dịch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8389A8)),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _reviews
                  .map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildReviewTile(review),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E335A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8389A8)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E335A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _user!.bio?.isNotEmpty == true
                ? _user!.bio!
                : 'Người dùng này chưa thêm mô tả.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4C4F6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(ProductCategory category, List<ProductModel> products) {
    final title = products.first.categoryDisplayName;
    final showTopRated = products.any((p) => p.viewCount > 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E335A),
              ),
            ),
            const SizedBox(width: 12),
            if (showTopRated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Nổi bật',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B4A),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/product-detail',
                    arguments: product.id,
                  );
                },
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: product.imageUrls.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrls.first,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: const Color(0xFFE1E5F8),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: Color(0xFF9AA0C2),
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.categoryDisplayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8389A8),
                              ),
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
      ],
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Đánh giá người bán',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8389A8),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _ratingCount == 0 ? '-' : _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E335A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFC857),
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _ratingCount == 0
                    ? 'Chưa có đánh giá'
                    : '$_ratingCount đánh giá',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8389A8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(SellerReview review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0E3FF),
                backgroundImage: review.buyerPhotoURL != null && review.buyerPhotoURL!.isNotEmpty
                    ? NetworkImage(review.buyerPhotoURL!)
                    : null,
                child: (review.buyerPhotoURL == null || review.buyerPhotoURL!.isEmpty)
                    ? Text(
                        review.buyerName.isNotEmpty
                            ? review.buyerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A4FB0),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.buyerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E335A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                          review.rating,
                          (index) => const Icon(Icons.star_rounded,
                              size: 16, color: Color(0xFFFFC857)),
                        ),
                        ...List.generate(
                          5 - review.rating,
                          (index) => const Icon(Icons.star_border_rounded,
                              size: 16, color: Color(0xFFFFC857)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd/MM/yyyy').format(review.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9AA0C2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4C4F6B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddReviewSheet(String buyerId) async {
    final currentUserData = await _authService.getUserData(buyerId);
    if (currentUserData == null) return;

    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Viết đánh giá về người bán',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E335A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        final starIndex = index + 1;
                        final filled = starIndex <= selectedRating;
                        return IconButton(
                          onPressed: () {
                            setModalState(() {
                              selectedRating = starIndex;
                            });
                          },
                          icon: Icon(
                            filled
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFC857),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn với người bán này...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) return;

                        final review = SellerReview(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          sellerId: widget.userId,
                          buyerId: buyerId,
                          buyerName: currentUserData.displayName,
                          buyerPhotoURL: currentUserData.photoURL,
                          rating: selectedRating,
                          comment: comment,
                          createdAt: DateTime.now(),
                        );

                        await _sellerReviewService.addReview(review);

                        // Cập nhật điểm trung bình & số lượng đánh giá trong collection reviews
                        final ratingSummary = await _sellerReviewService.getSellerRatingSummary(widget.userId);
                        final reviewsStream = _sellerReviewService.getReviewsForSeller(widget.userId);
                        final reviews = await reviewsStream;

                        // Đồng bộ vào document users/{sellerId}
                        await _authService.updateSellerRating(
                          widget.userId,
                          ratingSummary['average'] as double,
                          ratingSummary['count'] as int,
                        );

                        // Gửi thông báo tới người bán
                        await _notificationService.addNotification(
                          AppNotification(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            userId: widget.userId,
                            title:
                                '${currentUserData.displayName} đã đánh giá bạn',
                            body:
                                'Đánh giá: ${selectedRating} sao - "$comment"',
                            type: AppNotificationType.sellerReviewed,
                            createdAt: DateTime.now(),
                            isRead: false,
                            relatedUserId: buyerId,
                          ),
                        );

                        if (mounted) {
                          setState(() {
                            _averageRating = ratingSummary['average'] as double;
                            _ratingCount = ratingSummary['count'] as int;
                            _reviews = reviews;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Gửi đánh giá'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
