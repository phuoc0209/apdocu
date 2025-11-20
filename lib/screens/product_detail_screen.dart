import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../widgets/smart_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label đã được sao chép'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSMS(String phone) async {
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hình ảnh sản phẩm (carousel nếu có nhiều ảnh)
                  widget.product.imageUrls.length > 1
                      ? Column(
                          children: [
                            SizedBox(
                              height: 300,
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemCount: widget.product.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return SmartImage(
                                    imageUrl: widget.product.imageUrls[index],
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            // Indicator dots
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.product.imageUrls.length,
                                  (index) => GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: _currentPage == index ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: _currentPage == index
                                            ? const Color(0xFF6C63FF)
                                            : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                          ),
                          child: SmartImage(
                            imageUrl: widget.product.firstImage.isNotEmpty ? widget.product.firstImage : null,
                            fit: BoxFit.cover,
                          ),
                        ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x1A6C63FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.product.category,
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          widget.product.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        // Price
                        Text(
                          '${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫',
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          'Mô tả',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: TextStyle(color: Colors.grey[700], fontSize: 15),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Seller info
                        Text(
                          'Thông tin người bán',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person_outline, color: Color(0xFF6C63FF)),
                                title: Text(
                                  widget.product.sellerName ?? 'Chưa cập nhật',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text('Tên người bán'),
                              ),
                              if (widget.product.sellerPhone != null)
                                ListTile(
                                  leading: const Icon(Icons.phone, color: Color(0xFF6C63FF)),
                                  title: Text(
                                    widget.product.sellerPhone!,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text('Số điện thoại'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () => _copyToClipboard(
                                          context,
                                          'Số điện thoại',
                                          widget.product.sellerPhone!,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.phone),
                                        color: Colors.green,
                                        onPressed: () => _callPhone(widget.product.sellerPhone!),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.product.sellerEmail != null)
                                ListTile(
                                  leading: const Icon(Icons.email_outlined, color: Color(0xFF6C63FF)),
                                  title: Text(
                                    widget.product.sellerEmail!,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text('Email'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy),
                                        onPressed: () => _copyToClipboard(
                                          context,
                                          'Email',
                                          widget.product.sellerEmail!,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.email),
                                        color: Colors.blue,
                                        onPressed: () => _sendEmail(widget.product.sellerEmail!),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A000000),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.product.sellerPhone != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _sendSMS(widget.product.sellerPhone!),
                      icon: const Icon(Icons.message),
                      label: const Text('Nhắn tin'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (widget.product.sellerPhone != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.product.sellerPhone != null
                        ? () => _callPhone(widget.product.sellerPhone!)
                        : null,
                    icon: const Icon(Icons.phone),
                    label: const Text('Gọi ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
