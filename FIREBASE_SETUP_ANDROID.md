# Hướng dẫn cấu hình Firebase cho Android

## Bước 1: Tạo Firebase Project

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" hoặc "Create a project"
3. Đặt tên project: `appdocu1` (hoặc tên khác tùy ý)
4. Disable Google Analytics (không cần thiết cho development)
5. Click "Create project"

## Bước 2: Thêm Android App vào Firebase

1. Trong Firebase Console, click biểu tượng Android
2. Điền thông tin:
   - **Android package name**: `com.example.appdocu1`
   - **App nickname**: `Trao Đổi Đồ Cũ` (tùy chọn)
   - **Debug signing certificate SHA-1**: Để trống (tùy chọn)
3. Click "Register app"

## Bước 3: Tải file google-services.json

1. Click "Download google-services.json"
2. Copy file vào thư mục: `android/app/`
3. Click "Next" → "Next" → "Continue to console"

## Bước 4: Enable Authentication

1. Trong Firebase Console, chọn "Authentication" từ menu bên trái
2. Click "Get started"
3. Chọn tab "Sign-in method"
4. Enable "Email/Password"
   - Click vào "Email/Password"
   - Toggle "Enable"
   - Click "Save"

## Bước 5: Tạo Firestore Database

1. Chọn "Firestore Database" từ menu
2. Click "Create database"
3. Chọn "Start in test mode" (cho development)
4. Chọn location: `asia-southeast1` (Singapore)
5. Click "Enable"

## Bước 6: Tạo Storage

1. Chọn "Storage" từ menu
2. Click "Get started"
3. Chọn "Start in test mode"
4. Click "Next" → "Done"

## Bước 7: Chạy ứng dụng

Sau khi hoàn tất các bước trên:

```bash
# Đợi emulator khởi động xong (có thể mất 1-2 phút)
flutter devices

# Khi thấy emulator trong danh sách:
flutter run
```

## Tạo Admin Account (sau khi đã đăng ký tài khoản đầu tiên)

1. Vào Firebase Console → Firestore Database
2. Tìm collection `users`
3. Click vào document của user cần làm admin
4. Thêm field mới:
   - Field: `isAdmin`
   - Type: `boolean`
   - Value: `true`
5. Click "Update"

## Lưu ý

- File `google-services.json` PHẢI nằm trong `android/app/`
- Không commit file này lên Git (đã có trong .gitignore)
- Test mode cho Firestore và Storage chỉ dùng cho development
- Nhớ cập nhật Security Rules sau khi deploy production

## Nếu gặp lỗi "Default FirebaseApp is not initialized"

Đảm bảo:
1. File `google-services.json` đã được đặt đúng vị trí
2. Đã chạy `flutter clean` và `flutter pub get`
3. Đã restart Android Studio và emulator
