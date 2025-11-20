class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl; // Ảnh chính (giữ để tương thích)
  final List<String> imageUrls; // Danh sách tất cả ảnh (tối đa 10)
  final String category;
  // Seller contact info (optional)
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerEmail;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.imageUrls,
    required this.category,
    this.sellerName,
    this.sellerPhone,
    this.sellerEmail,
  });

  // Getter để lấy ảnh đầu tiên hoặc ảnh chính
  String get firstImage => imageUrls.isNotEmpty ? imageUrls.first : imageUrl;
  
  // Getter để kiểm tra có ảnh không
  bool get hasImages => imageUrls.isNotEmpty || imageUrl.isNotEmpty;
}
