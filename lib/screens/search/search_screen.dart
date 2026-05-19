import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/location_service.dart';
import '../../widgets/product_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<ProductModel> _searchResults = [];
  List<ProductModel> _suggestions = [];
  List<ProductModel> _featuredProducts = [];
  bool _isLoading = false;
  bool _showFilters = false;

  // Filter values
  ProductCategory? _selectedCategory;
  ProductCondition? _selectedCondition;
  double? _selectedDistance;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadFeaturedProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    final position = await _locationService.getCurrentPosition();
    setState(() {
      _userPosition = position;
    });
  }

  // Tải danh sách sản phẩm nổi bật/đang còn để hiển thị mặc định
  Future<void> _loadFeaturedProducts() async {
    try {
      // Tạm thời dùng searchProducts không keyword, không filter để lấy danh sách đã duyệt
      final results = await _productService.searchProducts(
        keyword: null,
        category: null,
        condition: null,
        userPosition: null,
        maxDistance: null,
      );

      // Sắp xếp theo lượt xem giảm dần và lấy tối đa 12 sản phẩm nổi bật
      results.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      setState(() {
        _featuredProducts = results.take(12).toList();
      });
    } catch (e) {
      debugPrint('Load featured products error: $e');
    }
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);

    try {
      final results = await _productService.searchProducts(
        keyword: _searchController.text.trim().isNotEmpty
            ? _searchController.text.trim()
            : null,
        category: _selectedCategory,
        condition: _selectedCondition,
        userPosition: _userPosition,
        maxDistance: _selectedDistance,
      );

      setState(() {
        _searchResults = results;
        // Khi đã bấm search, ẩn danh sách gợi ý để chỉ còn kết quả chính
        _suggestions = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedCondition = null;
      _selectedDistance = null;
      _searchController.clear();
      _searchResults = [];
      _showFilters = false;
    });
  }

  Widget _buildSearchAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF644EC5), Color(0xFF7D5CF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF7D5CF7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            textInputAction: TextInputAction.search,
                            decoration: const InputDecoration(
                              hintText: 'Tìm kiếm sản phẩm',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) => _onSearchTextChanged(value),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFB8B2E3),
                            ),
                          ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showFilters = !_showFilters);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EEFF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _showFilters
                                  ? Icons.tune_rounded
                                  : Icons.filter_list_rounded,
                              color: const Color(0xFF7D5CF7),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _searchController.text.isEmpty
                  ? 'Khám phá những món đồ nổi bật'
                  : 'Kết quả cho "${_searchController.text}"',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return AnimatedCrossFade(
      crossFadeState:
          _showFilters ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 220),
      firstChild: Container(
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterGroup(
              title: 'Danh mục',
              chips: [
                _buildFilterChip('Đồ gia dụng',
                    isSelected: _selectedCategory == ProductCategory.homeAppliances,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCategory =
                        selected ? ProductCategory.homeAppliances : null;
                  });
                }),
                _buildFilterChip('Thời trang',
                    isSelected: _selectedCategory == ProductCategory.fashion,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? ProductCategory.fashion : null;
                  });
                }),
                _buildFilterChip('Điện tử',
                    isSelected: _selectedCategory == ProductCategory.electronics,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCategory =
                        selected ? ProductCategory.electronics : null;
                  });
                }),
                _buildFilterChip('Sách vở',
                    isSelected: _selectedCategory == ProductCategory.books,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? ProductCategory.books : null;
                  });
                }),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilterGroup(
              title: 'Tình trạng',
              chips: [
                _buildFilterChip('Mới 90-100%',
                    isSelected: _selectedCondition == ProductCondition.new90to100,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCondition =
                        selected ? ProductCondition.new90to100 : null;
                  });
                }),
                _buildFilterChip('Dùng ít',
                    isSelected: _selectedCondition == ProductCondition.usedLittle,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCondition =
                        selected ? ProductCondition.usedLittle : null;
                  });
                }),
                _buildFilterChip('Dùng vừa',
                    isSelected:
                        _selectedCondition == ProductCondition.usedModerate,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCondition =
                        selected ? ProductCondition.usedModerate : null;
                  });
                }),
                _buildFilterChip('Dùng nhiều',
                    isSelected: _selectedCondition == ProductCondition.usedMuch,
                    onSelected: (selected) {
                  setState(() {
                    _selectedCondition =
                        selected ? ProductCondition.usedMuch : null;
                  });
                }),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilterGroup(
              title: 'Khoảng cách',
              helper: _userPosition == null
                  ? 'Cần cấp quyền vị trí để sử dụng bộ lọc này'
                  : null,
              chips: [
                _buildDistanceChip('1 km', 1),
                _buildDistanceChip('5 km', 5),
                _buildDistanceChip('10 km', 10),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7D5CF7),
                      side: const BorderSide(color: Color(0xFFCEC8F5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Xóa bộ lọc'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _search,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7D5CF7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Áp dụng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }

  Widget _buildFilterGroup({
    required String title,
    List<Widget>? chips,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF4C4F6B),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(
              color: Color(0xFF9AA0C2),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: chips ?? [],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label, {
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: const Color(0xFFF2F1FF),
      selectedColor: const Color(0xFF7D5CF7),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4C4F6B),
        fontWeight: FontWeight.w500,
      ),
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildDistanceChip(String label, double value) {
    final isSelected = _selectedDistance == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: const Color(0xFFF2F1FF),
      selectedColor: const Color(0xFF7D5CF7),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4C4F6B),
        fontWeight: FontWeight.w500,
      ),
      onSelected: _userPosition != null
          ? (selected) {
              setState(() {
                _selectedDistance = selected ? value : null;
              });
            }
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildResultList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Nếu không có từ khóa và không có kết quả tìm kiếm, hiển thị danh sách nổi bật
    if (_searchController.text.isEmpty && _searchResults.isEmpty) {
      if (_featuredProducts.isEmpty) {
        final horizontalPadding = (MediaQuery.of(context).size.width * 0.18)
            .clamp(24.0, 120.0);

        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: const Text(
              'Chưa có sản phẩm nổi bật để hiển thị.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9AA0C2),
                fontSize: 15,
              ),
            ),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 18,
          childAspectRatio: 0.72,
        ),
        itemCount: _featuredProducts.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/product-detail',
                arguments: product.id,
              );
            },
          );
        },
      );
    }

    if (_searchResults.isEmpty) {
      final horizontalPadding = (MediaQuery.of(context).size.width * 0.18)
          .clamp(24.0, 120.0);

      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: const Text(
            'Nhập từ khóa hoặc sử dụng bộ lọc để tìm kiếm sản phẩm phù hợp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9AA0C2),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 18,
        childAspectRatio: 0.72,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/product-detail',
              arguments: product.id,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Column(
        children: [
          _buildSearchAppBar(),
          _buildFilterSection(),
          // Nếu đang gõ và có gợi ý, ưu tiên hiển thị gợi ý; nếu đã search, hiển thị kết quả
          Expanded(
            child: _suggestions.isNotEmpty && _searchController.text.isNotEmpty
                ? _buildSuggestionList()
                : _buildResultList(),
          ),
        ],
      ),
    );
  }

  // Gọi mỗi khi text thay đổi để tải gợi ý nhẹ
  Future<void> _onSearchTextChanged(String value) async {
    setState(() {}); // cập nhật text hiển thị tiêu đề

    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        // Khi xóa hết text, cũng xóa kết quả tìm kiếm để quay về danh sách nổi bật
        _searchResults = [];
      });
      return;
    }

    try {
      // Tận dụng searchProducts nhưng không áp dụng filter khoảng cách
      final results = await _productService.searchProducts(
        keyword: query,
        category: _selectedCategory,
        condition: _selectedCondition,
        userPosition: null,
        maxDistance: null,
      );

      // Chỉ lấy tối đa 8 gợi ý để danh sách gọn
      setState(() {
        _suggestions = results.take(8).toList();
      });
    } catch (e) {
      // Không hiện snackbar liên tục khi đang gõ, chỉ log nhẹ
      debugPrint('Search suggestion error: $e');
    }
  }

  Widget _buildSuggestionList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search, color: Color(0xFF7D5CF7)),
          title: Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            product.categoryDisplayName,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8389A8)),
          ),
          onTap: () {
            // Đi tới trang chi tiết sản phẩm và ẩn gợi ý
            Navigator.pushNamed(
              context,
              '/product-detail',
              arguments: product.id,
            );
            setState(() {
              _suggestions = [];
              _searchController.text = product.title;
            });
          },
        );
      },
    );
  }
}
