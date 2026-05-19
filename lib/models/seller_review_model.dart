import 'package:cloud_firestore/cloud_firestore.dart';

class SellerReview {
  final String id;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final String? buyerPhotoURL;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  SellerReview({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhotoURL,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhotoURL': buyerPhotoURL,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory SellerReview.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerReview(
      id: data['id'] ?? doc.id,
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      buyerPhotoURL: data['buyerPhotoURL'],
      rating: (data['rating'] ?? 0) as int,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
