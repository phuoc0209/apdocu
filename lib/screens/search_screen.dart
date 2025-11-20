// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products.dart';
import '../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    final filteredProducts = productsProvider.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      productsProvider.search('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            productsProvider.search(value);
            setState(() {});
          },
          onSubmitted: (value) {
            productsProvider.search(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, productsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (productsProvider.selectedCategory != null || productsProvider.searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (productsProvider.searchQuery.isNotEmpty)
                            Chip(
                              label: Text('Tìm: ${productsProvider.searchQuery}'),
                              onDeleted: () {
                                _searchController.clear();
                                productsProvider.search('');
                              },
                            ),
                          if (productsProvider.selectedCategory != null)
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
          // Products list
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty ? Icons.search : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Nhập từ khóa để tìm kiếm'
                              : 'Không tìm thấy sản phẩm nào',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (ctx, i) => ProductCard(product: filteredProducts[i]),
                  ),
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
              'Bộ lọc',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            const Text('Sắp xếp:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            RadioListTile<String>(
              title: const Text('Mới nhất'),
              value: 'newest',
              groupValue: provider.sortBy,
              onChanged: (value) {
                if (value != null) {
                  provider.sort(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Giá: Thấp → Cao'),
              value: 'price_low',
              groupValue: provider.sortBy,
              onChanged: (value) {
                if (value != null) {
                  provider.sort(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Giá: Cao → Thấp'),
              value: 'price_high',
              groupValue: provider.sortBy,
              onChanged: (value) {
                if (value != null) {
                  provider.sort(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Tên: A → Z'),
              value: 'name',
              groupValue: provider.sortBy,
              onChanged: (value) {
                if (value != null) {
                  provider.sort(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

