import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/comment_model.dart';
import 'firestore_image_service.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreImageService _imageService = FirestoreImageService();

  // Create product
  Future<String> createProduct(ProductModel product, List<XFile> images) async {
    try {
      // Upload images
      List<String> imageUrls = await _uploadImages(images, product.id);

      // Create product with image URLs
      ProductModel productWithImages = product.copyWith(imageUrls: imageUrls);

      await _firestore
          .collection('products')
          .doc(product.id)
          .set(productWithImages.toMap());

      return product.id;
    } catch (e) {
      print('Create product error: $e');
      rethrow;
    }
  }

  // Update product
  Future<void> updateProduct(
      ProductModel product, List<XFile>? newImages) async {
    try {
      List<String> imageUrls = product.imageUrls;

      // Upload new images if provided
      if (newImages != null && newImages.isNotEmpty) {
        List<String> newImageUrls =
            await _uploadImages(newImages, product.id);
        imageUrls = [...imageUrls, ...newImageUrls];
      }

      ProductModel updatedProduct = product.copyWith(
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updatedProduct.toMap());
    } catch (e) {
      print('Update product error: $e');
      rethrow;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      // Delete images from storage
      await _deleteProductImages(productId);

      // Delete product document
      await _firestore.collection('products').doc(productId).delete();

      // Delete associated comments
      final comments = await _firestore
          .collection('comments')
          .where('productId', isEqualTo: productId)
          .get();

      for (var doc in comments.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Delete product error: $e');
      rethrow;
    }
  }

  // Get product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Get product error: $e');
      return null;
    }
  }

  // Get all approved products
  Stream<List<ProductModel>> getApprovedProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  // Get products by user
  Stream<List<ProductModel>> getUserProducts(String userId) {
    return _firestore
        .collection('products')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
          products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return products;
        });
  }

  // Get pending products (for admin)
  Stream<List<ProductModel>> getPendingProducts() {
    return _firestore
        .collection('products')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
          products.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return products;
        });
  }

  // Approve product (admin)
  Future<void> approveProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return;

      final product = ProductModel.fromDocument(doc);

      await _firestore.collection('products').doc(productId).update({
        'status': 'approved',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Thông báo cho chủ bài đăng
      await NotificationService().addNotification(
        AppNotification(
          id: _firestore.collection('tmp').doc().id,
          userId: product.ownerId,
          type: AppNotificationType.postApproved,
          title: 'Bài đăng đã được duyệt',
          body: 'Bài "${product.title}" đã được admin duyệt và hiển thị.',
          relatedProductId: productId,
          relatedUserId: null,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Approve product error: $e');
      rethrow;
    }
  }

  // Reject product (admin)
  Future<void> rejectProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) return;

      final product = ProductModel.fromDocument(doc);

      await _firestore.collection('products').doc(productId).update({
        'status': 'rejected',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await NotificationService().addNotification(
        AppNotification(
          id: _firestore.collection('tmp').doc().id,
          userId: product.ownerId,
          type: AppNotificationType.postRejected,
          title: 'Bài đăng không được duyệt',
          body:
              'Bài "${product.title}" không được duyệt. Vui lòng kiểm tra lại nội dung.',
          relatedProductId: productId,
          relatedUserId: null,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Reject product error: $e');
      rethrow;
    }
  }

  // Mark product as sold out
  Future<void> markAsSoldOut(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'status': 'soldOut',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Mark as sold out error: $e');
      rethrow;
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Increment view count error: $e');
    }
  }

  // Search products with filters
  Future<List<ProductModel>> searchProducts({
    String? keyword,
    ProductCategory? category,
    ProductCondition? condition,
    Position? userPosition,
    double? maxDistance, // in km
  }) async {
    try {
      Query query = _firestore
          .collection('products')
          .where('status', isEqualTo: 'approved');

      if (category != null) {
        query = query.where('category',
            isEqualTo: category.toString().split('.').last);
      }

      if (condition != null) {
        query = query.where('condition',
            isEqualTo: condition.toString().split('.').last);
      }

      QuerySnapshot snapshot = await query.get();
      List<ProductModel> products = snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList();

      // Filter by keyword (search in title and description)
      if (keyword != null && keyword.isNotEmpty) {
        products = products.where((product) {
          return product.title.toLowerCase().contains(keyword.toLowerCase()) ||
              product.description.toLowerCase().contains(keyword.toLowerCase()) ||
              product.tags
                  .any((tag) => tag.toLowerCase().contains(keyword.toLowerCase()));
        }).toList();
      }

      // Filter by distance
      if (userPosition != null && maxDistance != null) {
        products = products.where((product) {
          if (product.location == null) return false;

          double distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            product.location!.latitude,
            product.location!.longitude,
          );

          return (distance / 1000) <= maxDistance; // Convert to km
        }).toList();
      }

      return products;
    } catch (e) {
      print('Search products error: $e');
      return [];
    }
  }

  // Add comment
  Future<void> addComment(CommentModel comment) async {
    try {
      await _firestore
          .collection('comments')
          .doc(comment.id)
          .set(comment.toMap());
    } catch (e) {
      print('Add comment error: $e');
      rethrow;
    }
  }

  // Get comments for product
  Stream<List<CommentModel>> getProductComments(String productId) {
    return _firestore
        .collection('comments')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs
              .map((doc) => CommentModel.fromDocument(doc))
              .toList();
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
    } catch (e) {
      print('Delete comment error: $e');
      rethrow;
    }
  }

  // Helper: Upload images to Firestore (as base64)
  Future<List<String>> _uploadImages(List<XFile> images, String productId) async {
    try {
      print('Uploading ${images.length} images to Firestore...');
      final imageUrls = await _imageService.uploadProductImages(images, productId);
      print('Successfully uploaded ${imageUrls.length}/${images.length} images');
      return imageUrls;
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    }
  }

  // Helper: Delete product images from Firestore
  Future<void> _deleteProductImages(String productId) async {
    try {
      await _firestore.collection('product_images').doc(productId).delete();
    } catch (e) {
      print('Delete images error: $e');
    }
  }
}
