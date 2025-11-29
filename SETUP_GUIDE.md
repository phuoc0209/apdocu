# Ứng Dụng Trao Đổi Đồ Cũ

Ứng dụng di động cho phép người dùng đăng bài, trao đổi đồ cũ với các tính năng đầy đủ.

## Tính năng chính

### Người dùng thường
- ✅ Đăng nhập / Đăng ký với Email & Password
- ✅ Trang chủ hiển thị sản phẩm đã được duyệt
- ✅ Tìm kiếm sản phẩm với bộ lọc:
  - Tìm kiếm theo từ khóa
  - Lọc theo danh mục (Đồ gia dụng, Thời trang, Điện tử, Sách vở)
  - Lọc theo tình trạng (Mới 90-100%, Dùng ít, Dùng vừa, Dùng nhiều)
  - Lọc theo khoảng cách (1km, 5km, 10km)
- ✅ Chi tiết sản phẩm với hình ảnh, mô tả, vị trí
- ✅ Comment vào bài viết sản phẩm
- ✅ Đăng sản phẩm mới (chờ admin duyệt)
- ✅ Quản lý sản phẩm của mình
- ✅ Chỉnh sửa bài viết đã đăng
- ✅ Đánh dấu "Sold Out" khi đã trao đổi
- ✅ Nhắn tin với người đăng bài
- ✅ Trang cá nhân với thông tin và số liệu follow
- ✅ Follow/Unfollow người dùng khác
- ✅ Xem danh sách sản phẩm của mình

### Admin
- ✅ Trang duyệt bài đăng sản phẩm
- ✅ Duyệt hoặc từ chối sản phẩm

## Công nghệ sử dụng

- **Flutter**: Framework phát triển ứng dụng
- **Firebase Authentication**: Đăng nhập/đăng ký
- **Cloud Firestore**: Database lưu trữ dữ liệu
- **Firebase Storage**: Lưu trữ hình ảnh
- **Geolocator**: Xác định vị trí người dùng
- **Provider**: Quản lý state
- **Cached Network Image**: Tối ưu hiển thị ảnh

## Cấu trúc thư mục

```
lib/
├── models/              # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── comment_model.dart
│   └── message_model.dart
├── services/            # Business logic
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── chat_service.dart
│   └── location_service.dart
├── screens/             # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── product/
│   │   ├── product_list_screen.dart
│   │   ├── product_detail_screen.dart
│   │   └── create_product_screen.dart
│   ├── chat/
│   │   ├── chat_list_screen.dart
│   │   └── chat_detail_screen.dart
│   ├── profile/
│   │   └── account_screen.dart
│   ├── admin/
│   │   └── admin_screen.dart
│   └── main_screen.dart
├── widgets/             # Reusable widgets
│   └── product_card.dart
└── main.dart           # Entry point
```

## Cài đặt và chạy ứng dụng

### Bước 1: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 2: Cấu hình Firebase

1. Tạo project Firebase tại [Firebase Console](https://console.firebase.google.com/)

2. Thêm ứng dụng Android và iOS vào project

3. Tải xuống file cấu hình:
   - Android: `google-services.json` → đặt vào `android/app/`
   - iOS: `GoogleService-Info.plist` → đặt vào `ios/Runner/`

4. Kích hoạt các dịch vụ Firebase:
   - **Authentication**: Email/Password
   - **Cloud Firestore**: Tạo database
   - **Storage**: Tạo bucket để lưu ảnh

5. Cấu hình Firestore Rules (tạm thời cho development):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true);
    }
    
    // Comments collection
    match /comments/{commentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
    
    // Chats collection
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participantIds;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

6. Cấu hình Storage Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Bước 3: Cấu hình quyền

#### Android (`android/app/src/main/AndroidManifest.xml`)

Thêm các quyền sau:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

#### iOS (`ios/Runner/Info.plist`)

Thêm các key sau:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Cần quyền truy cập vị trí để hiển thị khoảng cách đến sản phẩm</string>
<key>NSCameraUsageDescription</key>
<string>Cần quyền truy cập camera để chụp ảnh sản phẩm</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Cần quyền truy cập thư viện ảnh để chọn ảnh sản phẩm</string>
```

### Bước 4: Chạy ứng dụng

```bash
# Android
flutter run

# iOS (cần macOS)
flutter run -d ios

# Web (experimental)
flutter run -d chrome
```

## Tạo tài khoản Admin

Sau khi tạo tài khoản người dùng đầu tiên, bạn cần cập nhật trường `isAdmin` trong Firestore:

1. Vào Firebase Console → Firestore
2. Tìm collection `users`
3. Chọn document của user cần set làm admin
4. Thêm/Cập nhật field `isAdmin: true`

## Cấu trúc Database

### Collection: users
```javascript
{
  uid: string,
  email: string,
  displayName: string,
  photoURL: string?,
  bio: string?,
  phoneNumber: string?,
  followers: [string],
  following: [string],
  isAdmin: boolean,
  createdAt: timestamp,
  lastActive: timestamp
}
```

### Collection: products
```javascript
{
  id: string,
  title: string,
  description: string,
  imageUrls: [string],
  category: string, // homeAppliances, fashion, electronics, books, other
  condition: string, // new90to100, usedLittle, usedModerate, usedMuch
  status: string, // pending, approved, rejected, soldOut
  ownerId: string,
  ownerName: string,
  ownerPhotoURL: string?,
  location: GeoPoint?,
  locationAddress: string?,
  createdAt: timestamp,
  updatedAt: timestamp,
  viewCount: number,
  tags: [string]
}
```

### Collection: comments
```javascript
{
  id: string,
  productId: string,
  userId: string,
  userName: string,
  userPhotoURL: string?,
  content: string,
  createdAt: timestamp,
  updatedAt: timestamp?
}
```

### Collection: chats
```javascript
{
  id: string,
  participantIds: [string],
  participantNames: {userId: userName},
  participantPhotos: {userId: photoURL},
  lastMessage: string?,
  lastMessageTime: timestamp?,
  lastMessageSenderId: string?,
  unreadCount: {userId: number},
  createdAt: timestamp
}

// Subcollection: messages
{
  id: string,
  chatId: string,
  senderId: string,
  senderName: string,
  senderPhotoURL: string?,
  content: string,
  createdAt: timestamp,
  isRead: boolean
}
```

## Lưu ý

- Ứng dụng yêu cầu kết nối Internet để hoạt động
- Cần cấp quyền truy cập vị trí để sử dụng tính năng lọc theo khoảng cách
- Hình ảnh sản phẩm nên có kích thước phù hợp để tối ưu tốc độ tải
- Admin cần được set thủ công trong Firestore

## Phát triển thêm

Các tính năng có thể mở rộng:
- [ ] Push notifications
- [ ] Real-time chat với typing indicator
- [ ] Đánh giá và review người dùng
- [ ] Lịch sử trao đổi
- [ ] Danh sách yêu thích
- [ ] Chia sẻ sản phẩm lên mạng xã hội
- [ ] Dark mode
- [ ] Đa ngôn ngữ
- [ ] Báo cáo vi phạm
- [ ] Analytics và thống kê

## Hỗ trợ

Nếu gặp vấn đề, vui lòng kiểm tra:
1. Firebase đã được cấu hình đúng
2. Dependencies đã được cài đặt đầy đủ
3. Quyền truy cập đã được cấp cho ứng dụng
4. Firestore Rules đã được cấu hình

## License

MIT License
