import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Service để lưu ảnh trong Firestore (thay Firebase Storage)
/// CHỈ dùng khi chưa upgrade Firebase plan
/// Tự động nén ảnh về kích thước phù hợp
class FirestoreImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Nén ảnh về kích thước mục tiêu
  Future<Uint8List> _compressImage(Uint8List bytes, {int targetSizeKB = 200, int quality = 85}) async {
    try {
      print('Compressing image from ${(bytes.length / 1024).toStringAsFixed(0)} KB...');
      
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('Cannot decode image');
        return bytes;
      }
      
      // Resize dần dần cho đến khi đạt target size
      int currentQuality = quality;
      int maxWidth = image.width;
      Uint8List compressed = bytes;
      
      while (compressed.length > targetSizeKB * 1024 && currentQuality > 10) {
        // Giảm width xuống 80% mỗi lần
        maxWidth = (maxWidth * 0.8).toInt();
        if (maxWidth < 200) maxWidth = 200;
        
        final resized = img.copyResize(image, width: maxWidth);
        compressed = Uint8List.fromList(img.encodeJpg(resized, quality: currentQuality));
        
        print('Resized to ${maxWidth}px, quality $currentQuality: ${(compressed.length / 1024).toStringAsFixed(0)} KB');
        
        // Giảm quality nếu vẫn còn lớn
        currentQuality -= 5;
      }
      
      print('Final compressed size: ${(compressed.length / 1024).toStringAsFixed(0)} KB');
      return compressed;
    } catch (e) {
      print('Error compressing image: $e');
      return bytes;
    }
  }

  /// Upload profile image - nén và lưu base64 vào Firestore
  Future<String> uploadProfileImage(XFile image, String userId) async {
    try {
      print('Reading image for Firestore...');
      final bytes = await image.readAsBytes();
      print('Original image size: ${(bytes.length / 1024).toStringAsFixed(0)} KB');
      
      // Nén ảnh xuống < 200KB để base64 không vượt quá 1MB
      final compressed = await _compressImage(bytes, targetSizeKB: 200);
      
      print('Converting to base64...');
      final base64Image = base64Encode(compressed);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';
      
      print('Base64 string length: ${(dataUrl.length / 1024).toStringAsFixed(0)} KB');
      
      // Kiểm tra size cuối cùng (Firestore field max ~1MB)
      if (dataUrl.length > 900 * 1024) {
        throw Exception('Ảnh vẫn quá lớn sau khi nén. Vui lòng chọn ảnh khác.');
      }
      
      print('Saving to Firestore...');
      await _firestore.collection('user_images').doc(userId).set({
        'profileImage': dataUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Profile image saved successfully');
      return dataUrl;
    } catch (e) {
      print('Error uploading to Firestore: $e');
      rethrow;
    }
  }

  /// Upload product images - nén và lưu base64 array vào Firestore
  Future<List<String>> uploadProductImages(List<XFile> images, String productId) async {
    List<String> dataUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        print('Processing image ${i + 1}/${images.length}...');
        final bytes = await images[i].readAsBytes();
        print('Original size: ${(bytes.length / 1024).toStringAsFixed(0)} KB');
        
        // Nén ảnh xuống < 300KB
        final compressed = await _compressImage(bytes, targetSizeKB: 300);
        
        final base64Image = base64Encode(compressed);
        final dataUrl = 'data:image/jpeg;base64,$base64Image';
        
        // Kiểm tra size
        if (dataUrl.length > 900 * 1024) {
          print('Image ${i + 1} still too large after compression, skipping');
          continue;
        }
        
        dataUrls.add(dataUrl);
        print('Image ${i + 1} ready (${(compressed.length / 1024).toStringAsFixed(0)} KB)');
      } catch (e) {
        print('Error processing image ${i + 1}: $e');
      }
    }
    
    // Lưu vào Firestore
    if (dataUrls.isNotEmpty) {
      print('Saving ${dataUrls.length} images to Firestore...');
      
      // Lưu từng ảnh riêng để tránh document quá lớn
      await _firestore.collection('product_images').doc(productId).set({
        'imageCount': dataUrls.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      for (int i = 0; i < dataUrls.length; i++) {
        await _firestore.collection('product_images').doc(productId)
          .collection('images').doc('img_$i').set({
            'data': dataUrls[i],
            'index': i,
          });
        print('Saved image ${i + 1}/${dataUrls.length}');
      }
    }
    
    return dataUrls;
  }

  /// Chuẩn hoá ảnh và trả về data URL (không lưu)
  Future<String> encodeImageAsDataUrl(
    XFile image, {
    int targetSizeKB = 240,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      final compressed = await _compressImage(bytes, targetSizeKB: targetSizeKB);
      final base64Image = base64Encode(compressed);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      if (dataUrl.length > 900 * 1024) {
        throw Exception('Ảnh quá lớn sau khi nén. Vui lòng chọn ảnh khác.');
      }

      return dataUrl;
    } catch (e) {
      print('Error encoding image: $e');
      rethrow;
    }
  }

  /// Get profile image
  Future<String?> getProfileImage(String userId) async {
    try {
      final doc = await _firestore.collection('user_images').doc(userId).get();
      return doc.data()?['profileImage'] as String?;
    } catch (e) {
      print('Error getting profile image: $e');
      return null;
    }
  }

  /// Get product images
  Future<List<String>> getProductImages(String productId) async {
    try {
      final doc = await _firestore.collection('product_images').doc(productId).get();
      final data = doc.data();
      
      if (data == null) return [];
      
      // Images được lưu riêng
      if (data.containsKey('imageCount')) {
        final imageCount = data['imageCount'] as int;
        final images = <String>[];
        
        for (int i = 0; i < imageCount; i++) {
          final imgDoc = await _firestore.collection('product_images')
            .doc(productId).collection('images').doc('img_$i').get();
          final imgData = imgDoc.data()?['data'] as String?;
          if (imgData != null) images.add(imgData);
        }
        
        return images;
      }
      
      return [];
    } catch (e) {
      print('Error getting product images: $e');
      return [];
    }
  }
}
