import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_image_service.dart';
import '../../services/product_service.dart';
import '../../utils/language_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final FirestoreImageService _imageService = FirestoreImageService();
  final ProductService _productService = ProductService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  UserModel? _userData;
  String? _profileImageUrl;
  String? _highlightImageUrl;
  bool _isLoadingProfile = true;
  bool _isLoadingProducts = true;
  List<ProductModel> _userProducts = [];
  Map<ProductCategory, List<ProductModel>> _groupedProducts = {};
  int _totalViews = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      setState(() {
        _isLoadingProfile = false;
        _isLoadingProducts = false;
      });
      return;
    }

    try {
      final data = await _authService.getUserData(_currentUser!.uid);

      String? imageUrl;
      try {
        imageUrl = await _imageService.getProfileImage(_currentUser!.uid);
      } catch (e) {
        debugPrint('Error loading profile image: $e');
      }

      if (!mounted) return;
      setState(() {
        _userData = data;
        _profileImageUrl = imageUrl;
        _isLoadingProfile = false;
      });
    } finally {
      _loadUserProducts();
    }
  }

  Future<void> _loadUserProducts() async {
    if (_currentUser == null) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
      return;
    }

    setState(() => _isLoadingProducts = true);

    try {
      final productsStream = _productService.getUserProducts(_currentUser!.uid);
      final products = await productsStream.first;

      final Map<ProductCategory, List<ProductModel>> grouped = {};
      for (final product in products) {
        grouped.putIfAbsent(product.category, () => []).add(product);
      }

      String? highlight;
      for (final product in products) {
        if (product.imageUrls.isNotEmpty) {
          highlight = product.imageUrls.first;
          break;
        }
      }

      final totalViews = products.fold<int>(0, (sum, p) => sum + p.viewCount);

      if (!mounted) return;
      setState(() {
        _userProducts = products;
        _groupedProducts = grouped;
        _highlightImageUrl = highlight;
        _totalViews = totalViews;
        _isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading user products: $e');
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile || _isLoadingProducts) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null || _userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FB),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: Color(0xFF6C63FF)),
                    const SizedBox(height: 16),
                    const Text(
                      'Đăng nhập để xem hồ sơ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E335A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hãy đăng nhập để quản lý thông tin và sản phẩm của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8389A8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login').then((_) => _loadUserData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FB),
        body: SafeArea(
          child: Column(
            children: [
              _buildProfileHeader(context),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildOverviewTab(),
                    _buildCoursesTab(),
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

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final joinDate = DateFormat('dd/MM/yyyy').format(_userData!.createdAt);
    final lastActive = _userData!.lastActive != null
        ? timeago.format(_userData!.lastActive!, locale: 'vi')
        : 'Hoạt động gần đây';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Only show a simple light background behind avatar instead of a big product image
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
                      backgroundImage: _profileImageUrl != null
                          ? CachedNetworkImageProvider(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(Icons.person, size: 40, color: Color(0xFF6C63FF))
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
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6C63FF)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              _userData!.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
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
                _buildTagChip(_userData!.isAdmin ? 'Admin' : 'Thành viên'),
                if (_userProducts.isNotEmpty) _buildTagChip('${_userProducts.length} sản phẩm'),
                _buildTagChip('Tham gia: $joinDate'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF6C63FF)),
                const SizedBox(width: 6),
                Text(
                  _userData!.email,
                  style: const TextStyle(color: Color(0xFF4C4F6B)),
                ),
                const SizedBox(width: 18),
                const Icon(Icons.access_time_filled_rounded, size: 18, color: Color(0xFF6C63FF)),
                const SizedBox(width: 6),
                Text(
                  lastActive,
                  style: const TextStyle(color: Color(0xFF4C4F6B)),
                ),
              ],
            ),
          ],
        ),
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
    final lp = LanguageProvider();
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
      child: TabBar(
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: Color(0xFF6C63FF), width: 3),
          insets: EdgeInsets.symmetric(horizontal: 30),
        ),
        labelColor: const Color(0xFF2E335A),
        unselectedLabelColor: const Color(0xFF9AA0C2),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: lp.translate('home')), // Overview
          const Tab(text: 'Courses'),
          const Tab(text: 'Review'),
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
              _buildMetricCard(Icons.inventory_2_outlined, 'Sản phẩm', '${_userProducts.length}'),
              _buildMetricCard(Icons.visibility_rounded, 'Lượt xem', '$_totalViews'),
              _buildMetricCard(Icons.people_outline, 'Người theo dõi', '${_userData!.followers.length}'),
            ],
          ),
          const SizedBox(height: 28),
          _buildAboutSection(),
          const SizedBox(height: 28),
          _buildMenuSection(),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Bạn chưa có sản phẩm nào đang hiển thị. Hãy đăng sản phẩm để bắt đầu trưng bày chúng tại đây.',
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
            _buildCourseSection(entry.key, entry.value),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.rate_review_outlined, size: 48, color: Color(0xFF6C63FF)),
          SizedBox(height: 16),
          Text(
            'Chưa có đánh giá nào',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E335A),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Khi có phản hồi từ người dùng, chúng sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8389A8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSection(ProductCategory category, List<ProductModel> products) {
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Top-rated',
                  style: TextStyle(
                    color: Color(0xFFE76F51),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildCourseCard(products[index]),
        ),
      ],
    );
  }

  Widget _buildCourseCard(ProductModel product) {
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-detail', arguments: product.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFE1E5F8),
                          child: const Icon(Icons.image_outlined, color: Color(0xFF9AA0C2)),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFE1E5F8),
                        child: const Icon(Icons.image_outlined, color: Color(0xFF9AA0C2)),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E335A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _userData!.displayName,
                      style: const TextStyle(
                        color: Color(0xFF8389A8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.conditionDisplayName,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.bookmark_border_rounded, size: 20, color: Color(0xFF6C63FF)),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFFFFA726)),
                        const SizedBox(width: 4),
                        Text(
                          '${product.viewCount} lượt xem',
                          style: const TextStyle(
                            color: Color(0xFF8389A8),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.schedule, size: 16, color: Color(0xFFB0B5D5)),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(product.createdAt, locale: 'vi'),
                          style: const TextStyle(
                            color: Color(0xFFB0B5D5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E335A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8389A8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final bio = _userData!.bio?.isNotEmpty == true
        ? _userData!.bio!
        : 'Bạn chưa cập nhật giới thiệu. Hãy chia sẻ thêm về bản thân để mọi người hiểu rõ hơn về bạn.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E335A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: const TextStyle(
              color: Color(0xFF4C4F6B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.edit,
            title: 'Chỉnh sửa hồ sơ',
            onTap: () async {
              await Navigator.pushNamed(context, '/edit-profile');
              if (mounted) _loadUserData();
            },
          ),
          const Divider(height: 1),
          if (_userData!.isAdmin)
            _buildMenuTile(
              icon: Icons.admin_panel_settings,
              title: 'Quản lý bài đăng',
              onTap: () => Navigator.pushNamed(context, '/admin'),
            ),
          if (_userData!.isAdmin) const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.settings,
            title: 'Cài đặt',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Trợ giúp',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.info_outline,
            title: 'Giới thiệu',
            onTap: () {},
          ),
          const Divider(height: 1),
          _buildMenuTile(
            icon: Icons.logout,
            title: 'Đăng xuất',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color iconColor = const Color(0xFF6C63FF),
    Color textColor = const Color(0xFF2E335A),
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: iconColor.withOpacity(0.6)),
      onTap: onTap,
    );
  }
}
