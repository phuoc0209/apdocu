# Hướng dẫn cấu hình Firebase Storage Rules

## Vấn đề hiện tại
Upload ảnh lên Firebase Storage bị chậm hoặc thất bại. Có thể do:
1. Rules chặn quyền write
2. Kết nối mạng chậm
3. File ảnh quá lớn

## Các bước khắc phục

### 1. Kiểm tra Firebase Storage Rules

1. Vào [Firebase Console](https://console.firebase.google.com)
2. Chọn project của bạn
3. Vào **Storage** > **Rules**
4. Đảm bảo rules cho phép upload:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Profile images - chỉ owner mới upload được
    match /profiles/{fileName} {
      allow read: if true; // Tất cả có thể đọc
      allow write: if request.auth != null && 
                     request.resource.size < 5 * 1024 * 1024 && // Max 5MB
                     request.resource.contentType.matches('image/.*');
    }
    
    // Product images - chỉ người đăng nhập mới upload được
    match /products/{productId}/{fileName} {
      allow read: if true; // Tất cả có thể đọc
      allow write: if request.auth != null && 
                     request.resource.size < 10 * 1024 * 1024 && // Max 10MB
                     request.resource.contentType.matches('image/.*');
    }
  }
}
```

5. Click **Publish** để lưu

### 2. Kiểm tra kích thước ảnh

Mở Chrome DevTools (F12) và xem Console khi upload ảnh. Sẽ thấy:
```
Profile image size: 2345678 bytes (2.24 MB)
Uploading to Firebase Storage...
```

Nếu file quá lớn (>5MB), nên resize trước khi upload.

### 3. Kiểm tra kết nối

1. Mở DevTools > Network tab
2. Filter by "XHR" hoặc "Fetch"
3. Upload ảnh và xem:
   - Request có gửi thành công không?
   - Response status là gì? (200 = OK, 403 = Forbidden, 401 = Unauthorized)
   - Thời gian request mất bao lâu?

### 4. Xem log trong Console

Khi upload, code đã thêm nhiều log:
```
Starting profile image upload...
Profile image size: 1234567 bytes (1.18 MB)
Uploading to Firebase Storage...
Getting download URL...
Profile image uploaded successfully: https://...
```

Nếu bị lỗi sẽ hiện:
```
Upload profile image error: [Chi tiết lỗi]
```

### 5. Timeout settings

Code đã set timeout:
- Upload: 60 giây
- Get URL: 30 giây

Nếu vẫn timeout, có thể:
- Mạng quá chậm
- File quá lớn
- Firebase Storage rules chặn

## Giải pháp nếu vẫn chậm

### Giảm kích thước ảnh trước khi upload

Thêm package `image` để resize:

```yaml
# pubspec.yaml
dependencies:
  image: ^4.0.17
```

Sau đó modify code:

```dart
import 'package:image/image.dart' as img;

Future<Uint8List> _compressImage(XFile file) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  
  if (image == null) return bytes;
  
  // Resize nếu lớn hơn 1200px
  final resized = image.width > 1200 
    ? img.copyResize(image, width: 1200)
    : image;
  
  // Compress với quality 85%
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
```

### Thêm progress indicator

Hiển thị % upload:

```dart
final uploadTask = ref.putData(bytes);

uploadTask.snapshotEvents.listen((snapshot) {
  final progress = snapshot.bytesTransferred / snapshot.totalBytes;
  print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
});

await uploadTask;
```

## Kiểm tra nhanh

1. Vào Chrome DevTools Console
2. Upload 1 ảnh nhỏ (< 500KB)
3. Xem log có hiện "uploaded successfully" không
4. Nếu thành công với ảnh nhỏ → vấn đề là file quá lớn
5. Nếu fail cả ảnh nhỏ → vấn đề là rules hoặc authentication
