import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service để quản lý ảnh: lưu, đọc, xóa ảnh từ file system
class ImageService {
  static ImageService? _instance;
  Directory? _imagesDirectory;

  ImageService._();

  static ImageService get instance {
    _instance ??= ImageService._();
    return _instance!;
  }

  /// Khởi tạo thư mục lưu ảnh
  Future<void> initialize() async {
    if (_imagesDirectory != null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _imagesDirectory = Directory(path.join(appDir.path, 'product_images'));
      
      if (!await _imagesDirectory!.exists()) {
        await _imagesDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo thư mục ảnh: $e');
    }
  }

  /// Lưu ảnh từ bytes và trả về tên file
  /// [imageBytes]: Bytes của ảnh
  /// [extension]: Phần mở rộng (jpg, png, etc.)
  /// Returns: Tên file đã lưu (ví dụ: "abc123.jpg")
  Future<String?> saveImage(Uint8List imageBytes, String extension) async {
    try {
      await initialize();
      if (_imagesDirectory == null) {
        debugPrint('Lỗi: _imagesDirectory là null');
        return null;
      }

      // Tạo tên file unique: timestamp + random
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 100000).toString().padLeft(5, '0');
      final fileName = 'img_${timestamp}_$random.$extension';
      final filePath = path.join(_imagesDirectory!.path, fileName);

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      // Kiểm tra file đã được lưu chưa
      if (await file.exists()) {
        debugPrint('✅ Đã lưu ảnh: $fileName (${imageBytes.length} bytes)');
        return fileName; // Chỉ trả về tên file, không phải full path
      } else {
        debugPrint('❌ Lỗi: File không tồn tại sau khi lưu: $filePath');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi lưu ảnh: $e');
      return null;
    }
  }

  /// Lưu ảnh từ file và trả về tên file
  Future<String?> saveImageFromFile(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final extension = path.extension(imageFile.path).replaceFirst('.', '');
      return await saveImage(bytes, extension.isEmpty ? 'jpg' : extension);
    } catch (e) {
      debugPrint('Lỗi lưu ảnh từ file: $e');
      return null;
    }
  }

  /// Đọc ảnh từ tên file
  /// [fileName]: Tên file (ví dụ: "abc123.jpg")
  /// Returns: File object hoặc null nếu không tìm thấy
  Future<File?> getImageFile(String fileName) async {
    try {
      await initialize();
      if (_imagesDirectory == null) {
        debugPrint('Lỗi: _imagesDirectory là null khi đọc ảnh: $fileName');
        return null;
      }

      final filePath = path.join(_imagesDirectory!.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        debugPrint('✅ Tìm thấy ảnh: $fileName');
        return file;
      } else {
        debugPrint('❌ Không tìm thấy ảnh: $filePath');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Lỗi đọc ảnh $fileName: $e');
      return null;
    }
  }

  /// Xóa ảnh theo tên file
  Future<bool> deleteImage(String fileName) async {
    try {
      await initialize();
      if (_imagesDirectory == null) return false;

      final filePath = path.join(_imagesDirectory!.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi xóa ảnh: $e');
      return false;
    }
  }

  /// Xóa nhiều ảnh
  Future<void> deleteImages(List<String> fileNames) async {
    for (final fileName in fileNames) {
      await deleteImage(fileName);
    }
  }

  /// Lấy đường dẫn đầy đủ của ảnh (để hiển thị)
  Future<String?> getImagePath(String fileName) async {
    try {
      await initialize();
      if (_imagesDirectory == null) return null;

      final filePath = path.join(_imagesDirectory!.path, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi lấy đường dẫn ảnh: $e');
      return null;
    }
  }

  /// Lấy thư mục chứa ảnh
  Future<Directory?> getImagesDirectory() async {
    await initialize();
    return _imagesDirectory;
  }
}

