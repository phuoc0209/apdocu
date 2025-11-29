# Hướng dẫn resize ảnh trước khi upload

## Hiện tại đang dùng Firestore thay Firebase Storage

**Giới hạn:**
- Ảnh profile: < 1MB
- Ảnh sản phẩm: < 500KB mỗi ảnh

## Cách resize ảnh (cho người dùng)

### Windows:
1. Chuột phải vào ảnh > **Edit with Photos**
2. Click **...** > **Resize**
3. Chọn kích thước nhỏ hơn hoặc custom
4. Save

### Online:
1. Vào https://tinypng.com hoặc https://compressor.io
2. Upload ảnh
3. Download ảnh đã nén

## Tích hợp resize trong app (tương lai)

Nếu muốn tự động resize trong app, thêm package `image`:

```yaml
# pubspec.yaml
dependencies:
  image: ^4.0.17
```

Sau đó tạo helper:

```dart
import 'package:image/image.dart' as img;
import 'dart:typed_data';

Future<Uint8List> resizeImage(Uint8List bytes, {int maxWidth = 800}) async {
  final image = img.decodeImage(bytes);
  if (image == null) return bytes;
  
  // Resize nếu lớn hơn maxWidth
  final resized = image.width > maxWidth 
    ? img.copyResize(image, width: maxWidth)
    : image;
  
  // Compress với quality 85%
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
```

## Lưu ý quan trọng

**Firestore document có giới hạn 1MB**, nên:
- 1 document profile chỉ lưu 1 ảnh
- 1 document product có thể lưu nhiều ảnh nhỏ
- Nếu ảnh quá nhiều/lớn → nên upgrade Firebase lên Blaze plan để dùng Storage

## Khi nào nên upgrade lên Blaze plan?

- Cần lưu ảnh > 1MB
- Có nhiều sản phẩm với nhiều ảnh
- Muốn tốc độ load nhanh hơn
- Không muốn giới hạn kích thước

**Blaze plan vẫn FREE** trong quota:
- 5GB storage
- 1GB download/ngày
- Chỉ trả tiền khi vượt quota
