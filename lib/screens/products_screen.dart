import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/product_card.dart';
import '../widgets/bottom_header.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/edit_product_dialog.dart';
import '../providers/products.dart';
import '../providers/auth.dart';
import 'search_screen.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;
  
  const ProductsScreen({super.key, this.onNavigateToProfile});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (index == 0) {
      // Tab "Tất cả sản phẩm"
      productsProvider.resetFilters();
    } else if (index == 1) {
      // Tab "Sản phẩm của tôi"
      if (authProvider.isLoggedIn && authProvider.userId != null) {
        productsProvider.filterBySeller(authProvider.userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final products = productsProvider.items;
    final isLoading = productsProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tất cả sản phẩm'),
            Tab(text: 'Sản phẩm của tôi'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'filter') {
                _showFilterDialog(context, productsProvider);
              } else if (value.startsWith('sort_')) {
                productsProvider.sort(value.replaceFirst('sort_', ''));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 8),
                    Text('Bộ lọc'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'sort_newest',
                child: Text('Mới nhất'),
              ),
              const PopupMenuItem(
                value: 'sort_price_low',
                child: Text('Giá: Thấp → Cao'),
              ),
              const PopupMenuItem(
                value: 'sort_price_high',
                child: Text('Giá: Cao → Thấp'),
              ),
              const PopupMenuItem(
                value: 'sort_name',
                child: Text('Tên: A → Z'),
              ),
            ],
          ),
        ],
      ),
          floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final messenger = ScaffoldMessenger.of(context);
          final localProductsProvider = productsProvider;

          // Kiểm tra đăng nhập
          if (!authProvider.isLoggedIn) {
            // Chuyển đến màn hình Profile (tab index 2)
            if (widget.onNavigateToProfile != null) {
              widget.onNavigateToProfile!();

              // Hiển thị thông báo
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Vui lòng đăng nhập để đăng sản phẩm'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }

          // Mở dialog đăng sản phẩm
          bool? res;
          if (kIsWeb) {
            res = await showDialog<bool>(
              context: context,
              builder: (_) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: const AddProductDialog(),
                  ),
                ),
              ),
            );
          } else {
            res = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => const AddProductDialog(),
            );
          }

          if (res == true) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Sản phẩm đã được thêm thành công!'),
                backgroundColor: Colors.green,
              ),
            );
            // Reload products sau khi thêm
            localProductsProvider.loadProducts();
          }
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Đăng sản phẩm', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tất cả sản phẩm
          _buildProductsList(context, productsProvider, products, isLoading, isMyProducts: false),
          // Tab 2: Sản phẩm của tôi
          authProvider.isLoggedIn
              ? _buildProductsList(context, productsProvider, products, isLoading, isMyProducts: true)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Vui lòng đăng nhập',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đăng nhập để xem sản phẩm của bạn',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ],
      ),
      bottomNavigationBar: const BottomHeader(title: 'Sản phẩm'),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    ProductsProvider productsProvider,
    List products,
    bool isLoading, {
    bool isMyProducts = false,
  }) {
    return Column(
      children: [
        // Filter chips (chỉ hiển thị ở tab "Tất cả sản phẩm")
        if (!isMyProducts && productsProvider.selectedCategory != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Chip(
                          label: Text('Danh mục: ${productsProvider.selectedCategory}'),
                          onDeleted: () => productsProvider.filterByCategory(null),
                        ),
                        TextButton(
                          onPressed: () => productsProvider.resetFilters(),
                          child: const Text('Xóa bộ lọc'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Products grid
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isMyProducts ? Icons.inventory_2_outlined : Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isMyProducts
                                ? 'Bạn chưa có sản phẩm nào'
                                : 'Chưa có sản phẩm nào',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isMyProducts
                                ? 'Nhấn nút "Đăng sản phẩm" để thêm sản phẩm đầu tiên'
                                : 'Nhấn nút "Đăng sản phẩm" để thêm sản phẩm đầu tiên',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        if (isMyProducts && authProvider.isLoggedIn && authProvider.userId != null) {
                          return productsProvider.loadProducts(sellerId: authProvider.userId);
                        }
                        return productsProvider.loadProducts();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: GridView.builder(
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (ctx, i) {
                            final product = products[i];
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final isMyProduct = isMyProducts && 
                                authProvider.isLoggedIn && 
                                authProvider.userId != null &&
                                product.sellerName == authProvider.username;
                            
                            return Stack(
                              children: [
                                ProductCard(product: product),
                                if (isMyProduct)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showEditDialog(context, product),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _showDeleteDialog(context, product),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, product) {
    final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => EditProductDialog(product: product),
    ).then((updated) {
      if (!mounted) return;
      if (updated == true) {
        if (authProvider.isLoggedIn && authProvider.userId != null) {
          productsProvider.filterBySeller(authProvider.userId);
        }
      }
    });
  }

  void _showDeleteDialog(BuildContext context, product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc chắn muốn xóa "${product.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final productsProvider = Provider.of<ProductsProvider>(context, listen: false);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              if (authProvider.userId != null) {
                final success = await productsProvider.deleteProduct(
                  product.id,
                  sellerId: authProvider.userId,
                );

                // Use captured navigator/messenger to avoid using BuildContext after await
                navigator.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa sản phẩm'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Lỗi khi xóa sản phẩm'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ProductsProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc theo danh mục',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProductsProvider.categories.map((category) {
                final isSelected = provider.selectedCategory == category ||
                    (provider.selectedCategory == null && category == 'Tất cả');
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.filterByCategory(category);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
