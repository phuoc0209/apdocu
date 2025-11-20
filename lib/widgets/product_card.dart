import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../providers/favorites.dart';
import '../providers/auth.dart';
import '../widgets/report_product_dialog.dart';
import 'smart_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;
  bool _checkingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      final isFav = await favoritesProvider.isFavorite(authProvider.userId!, int.parse(widget.product.id));
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _checkingFavorite = false;
        });
      }
    } else {
      setState(() => _checkingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
    
    if (!authProvider.isLoggedIn || authProvider.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào yêu thích'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isFavorite = !_isFavorite);

    final success = _isFavorite
        ? await favoritesProvider.addFavorite(authProvider.userId!, int.parse(widget.product.id))
        : await favoritesProvider.removeFavorite(authProvider.userId!, int.parse(widget.product.id));

    if (!success && mounted) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Lỗi khi thêm yêu thích' : 'Lỗi khi xóa yêu thích'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (_) => ReportProductDialog(
        productId: int.parse(widget.product.id),
        productTitle: widget.product.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductDetailScreen(product: widget.product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0x0A000000), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 1.4,
                  child: SmartImage(
                    imageUrl: widget.product.firstImage.isNotEmpty ? widget.product.firstImage : null,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.product.title,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        widget.product.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            '${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF4A6CF7),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (value) {
                            if (value == 'favorite') {
                              _toggleFavorite();
                            } else if (value == 'report') {
                              _showReportDialog();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'favorite',
                              child: Row(
                                children: [
                                  Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, size: 20),
                                  const SizedBox(width: 8),
                                  Text(_isFavorite ? 'Bỏ yêu thích' : 'Thêm yêu thích'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.flag, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Báo cáo sản phẩm'),
                                ],
                              ),
                            ),
                          ],
                        )
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
}
