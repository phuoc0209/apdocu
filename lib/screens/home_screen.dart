import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../providers/products.dart';
import '../providers/cart.dart';
import '../widgets/smart_image.dart';
import 'search_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tất cả';
  final PageController _bannerController = PageController(viewportFraction: 0.92);
  int _currentBannerPage = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final allProducts = productsProvider.allItems;
    
    if (_selectedCategory == 'Tất cả') {
      return allProducts.take(8).toList(); // Hiển thị 8 sản phẩm đầu tiên
    }
    return allProducts
        .where((p) => p.category == _selectedCategory)
        .take(8)
        .toList();
  }

  List<Product> get _bannerProducts {
    final productsProvider = Provider.of<ProductsProvider>(context);
    return productsProvider.allItems.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productsProvider = Provider.of<ProductsProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isLoading = productsProvider.isLoading;
    final filteredProducts = _filteredProducts;
    final bannerProducts = _bannerProducts;
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            // Logo
            Container(
              width: isWide ? 40 : 36,
              height: isWide ? 40 : 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9D8CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.store, color: Colors.white, size: isWide ? 22 : 20),
            ),
            SizedBox(width: isWide ? 16 : 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                child: Container(
                  height: isWide ? 44 : 40,
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey, size: isWide ? 22 : 20),
                      SizedBox(width: isWide ? 12 : 8),
                      Text(
                        'Tìm sản phẩm, thương hiệu...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: isWide ? 15 : 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: isWide ? 16 : 12),
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.black87,
                    size: isWide ? 26 : 24,
                  ),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: isWide ? 10 : 8,
                    top: isWide ? 10 : 8,
                    child: Container(
                      padding: EdgeInsets.all(isWide ? 5 : 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C63FF),
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: isWide ? 18 : 16,
                        minHeight: isWide ? 18 : 16,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWide ? 11 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => productsProvider.loadProducts(),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Categories
            SizedBox(
              height: 80,
              child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        scrollDirection: Axis.horizontal,
                        children: ProductsProvider.categories.map((c) {
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = c),
                            child: _buildCategory(
                              context,
                              _iconForCategory(c),
                              c,
                              selected: _selectedCategory == c,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Banner carousel
                    if (bannerProducts.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 180,
                            child: PageView.builder(
                              controller: _bannerController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentBannerPage = index;
                                });
                              },
                              itemCount: bannerProducts.length,
                              itemBuilder: (context, index) {
                                final product = bannerProducts[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        SmartImage(
                                          imageUrl: product.firstImage.isNotEmpty ? product.firstImage : null,
                                          fit: BoxFit.cover,
                                        ),
                                        // Gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Color.fromRGBO(0, 0, 0, 0.6),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Product info overlay
                                        Positioned(
                                          bottom: 16,
                                          left: 16,
                                          right: 16,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.title,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
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
                          if (bannerProducts.length > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  bannerProducts.length,
                                  (index) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _currentBannerPage == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: _currentBannerPage == index
                                          ? const Color(0xFF6C63FF)
                                          : Colors.grey[300],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // Section title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory == 'Tất cả' ? 'Sản phẩm nổi bật' : _selectedCategory,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (filteredProducts.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                // Navigate to products screen - sẽ được xử lý bởi navigation
                                // Có thể dùng Navigator hoặc TabController tùy vào cấu trúc app
                              },
                              child: const Text('Xem tất cả'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Product grid - Responsive
                    if (filteredProducts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có sản phẩm nào',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy đăng sản phẩm đầu tiên của bạn!',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive grid: 2 columns on mobile, 3-4 on tablet, 4-5 on desktop
                          final crossAxisCount = constraints.maxWidth < 600
                              ? 2
                              : constraints.maxWidth < 900
                                  ? 3
                                  : constraints.maxWidth < 1200
                                      ? 4
                                      : 5;
                          final spacing = constraints.maxWidth < 600 ? 12.0 : 16.0;
                          final aspectRatio = constraints.maxWidth < 600 ? 0.68 : 0.72;

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth < 600 ? 12.0 : 16.0,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredProducts.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: spacing,
                                crossAxisSpacing: spacing,
                                childAspectRatio: aspectRatio,
                              ),
                              itemBuilder: (ctx, i) => ProductCard(product: filteredProducts[i]),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Điện tử':
        return Icons.devices;
      case 'Thời trang':
        return Icons.checkroom;
      case 'Đồ gia dụng':
        return Icons.home;
      case 'Sách':
        return Icons.menu_book;
      case 'Thể thao':
        return Icons.sports_soccer;
      case 'Xe cộ':
        return Icons.directions_car;
      case 'Đồ chơi':
        return Icons.toys;
      case 'Khác':
        return Icons.category;
      default:
        return Icons.grid_view;
    }
  }

  Widget _buildCategory(BuildContext context, IconData icon, String label, {bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF6C63FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0x4D6C63FF)
                        : const Color(0x0D000000),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF6C63FF),
                size: 20,
              ),
            ),
            const SizedBox(height: 1),
            Flexible(
              child: SizedBox(
                width: 70,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? const Color(0xFF6C63FF) : Colors.black87,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
