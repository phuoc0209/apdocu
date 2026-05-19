import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../utils/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  ProductCategory? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.style_outlined,
      'label': 'Thời trang',
      'value': ProductCategory.fashion,
    },
    {
      'icon': Icons.devices_other_outlined,
      'label': 'Điện tử',
      'value': ProductCategory.electronics,
    },
    {
      'icon': Icons.menu_book_outlined,
      'label': 'Sách vở',
      'value': ProductCategory.books,
    },
    {
      'icon': Icons.chair_alt_outlined,
      'label': 'Gia dụng',
      'value': ProductCategory.homeAppliances,
    },
    {
      'icon': Icons.sports_esports_outlined,
      'label': 'khác',
      'value': ProductCategory.other,
    },
  ];

  static const Color _primaryColor = Color(0xFF6A5AE0);
  static const Color _backgroundColor = Color(0xFFF6F7FB);
  static const Color _chipBackground = Color(0xFFEDEAFF);
  static const Color _textMuted = Color(0xFF82829A);

  String _getConditionText(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.new90to100:
        return 'Còn mới 90-100%';
      case ProductCondition.usedLittle:
        return 'Dùng ít';
      case ProductCondition.usedModerate:
        return 'Dùng vừa';
      case ProductCondition.usedMuch:
        return 'Dùng nhiều';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = LanguageProvider();
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lp.translate('home'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: _textMuted,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lp.translate('app_name'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.08),
                        child: IconButton(
                          tooltip: 'Thông báo',
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: _primaryColor,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCategoryTabs(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: FutureBuilder<List<ProductModel>>(
                  future: _productService.getApprovedProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Lỗi: ${snapshot.error}'),
                      );
                    }

                    var products = snapshot.data ?? [];

                    if (_selectedCategory != null) {
                      products = products
                          .where((p) => p.category == _selectedCategory)
                          .toList();
                    }

                    products = products
                        .where((p) => p.status != ProductStatus.soldOut)
                        .toList();

                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 84, color: _textMuted.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory != null
                                  ? 'Chưa có món nào trong danh mục này'
                                  : 'Chưa có sản phẩm nào được duyệt',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: _textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: _primaryColor,
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.6,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _buildProductCard(product);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/search'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: _primaryColor.withOpacity(0.8), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                LanguageProvider().translate('search_placeholder'),
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune_rounded, size: 18, color: _primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isSelected = _selectedCategory == category['value'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = isSelected ? null : category['value'];
              });
            },
            child: SizedBox(
              width: 110,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(isSelected ? 0.15 : 0.06),
                      blurRadius: isSelected ? 16 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category['icon'],
                      size: 22,
                      color: isSelected ? Colors.white : _primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category['label'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product-detail',
          arguments: product.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: product.imageUrls.isNotEmpty
                        ? Image.network(
                            product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: _chipBackground,
                                alignment: Alignment.center,
                                child: Icon(Icons.image_outlined,
                                    size: 42, color: _textMuted.withOpacity(0.5)),
                              );
                            },
                          )
                        : Container(
                            color: _chipBackground,
                            alignment: Alignment.center,
                            child: Icon(Icons.image_outlined,
                                size: 42, color: _textMuted.withOpacity(0.5)),
                          ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.favorite_border,
                          color: _primaryColor.withOpacity(0.8)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng Yêu thích sẽ sớm có mặt!'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: _textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.locationAddress ?? product.categoryDisplayName,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                        const Icon(Icons.visibility_rounded,
                          size: 18, color: Color(0xFFFFA726)),
                      const SizedBox(width: 2),
                      Text(
                        product.viewCount.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(product.categoryDisplayName),
                      const SizedBox(width: 8),
                      _buildInfoChip(product.conditionDisplayName,
                          isPrimary: true),
                      const Spacer(),
                      Text(
                        product.statusDisplayName,
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
  }

  Widget _buildInfoChip(String text, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? _primaryColor.withOpacity(0.12) : _chipBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isPrimary ? _primaryColor : _textMuted,
        ),
      ),
    );
  }
}
