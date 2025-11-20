import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/image_service.dart';

/// Widget thông minh để hiển thị ảnh từ nhiều nguồn:
/// - Base64 data URL (data:image/...)
/// - Network URL (http://, https://)
/// - Local file path
/// - Placeholder nếu không có ảnh
class SmartImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Nếu không có imageUrl, hiển thị placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    final url = imageUrl!;
    final imageService = ImageService.instance;

    // Kiểm tra nếu là tên file (không có /, http, data:)
    // Tên file thường có format: img_1234567890_12345.jpg
    if (!url.contains('/') && !url.startsWith('http') && !url.startsWith('data:') && !url.startsWith('file:')) {
      // Có thể là tên file từ ImageService
      return FutureBuilder<File?>(
        future: imageService.getImageFile(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return placeholder ?? _buildPlaceholder();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Lỗi hiển thị ảnh file: $url - $error');
                return _buildError();
              },
            );
          }
          debugPrint('❌ Không tìm thấy file ảnh: $url');
          return _buildError();
        },
      );
    }

    // Base64 image (tương thích với dữ liệu cũ)
    if (url.startsWith('data:image')) {
      try {
        final parts = url.split(',');
        if (parts.length < 2) {
          return _buildError();
        }
        final base64String = parts[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    }

    // Network image
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }

    // Local file path
    if (url.startsWith('/') || url.startsWith('file://')) {
      try {
        final filePath = url.replaceFirst('file://', '');
        return Image.file(
          File(filePath),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _buildError(),
        );
      } catch (e) {
        return _buildError();
      }
    }

    // Unknown format
    return _buildError();
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_outlined,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.3 : height! * 0.3)
            : 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildError() {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.image_not_supported,
        size: (width != null && height != null) 
            ? (width! < height! ? width! * 0.3 : height! * 0.3)
            : 48,
        color: Colors.grey[400],
      ),
    );
  }
}

