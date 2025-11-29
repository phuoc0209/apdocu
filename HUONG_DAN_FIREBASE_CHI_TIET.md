# 🔥 HƯỚNG DẪN CẤU HÌNH FIREBASE CHI TIẾT

## ✅ Tôi đã cấu hình sẵn các file Android cho bạn!

Các file sau đã được cập nhật:
- ✅ `android/build.gradle.kts` - Thêm Google Services plugin
- ✅ `android/app/build.gradle.kts` - Cấu hình Firebase dependencies
- ✅ Đặt minSdk = 21 (yêu cầu của Firebase)

## 📋 BẠN CẦN LÀM CÁC BƯỚC SAU:

### Bước 1️⃣: Tạo Firebase Project (5 phút)

1. Mở trình duyệt và truy cập: **https://console.firebase.google.com/**
2. Đăng nhập bằng Google Account
3. Click **"Add project"** hoặc **"Create a project"**
4. Nhập tên: **`appdocu1`** → Click **"Continue"**
5. Tắt Google Analytics (toggle OFF) → Click **"Create project"**
6. Đợi 10 giây → Click **"Continue"**

✅ **Hoàn thành Bước 1**

---

### Bước 2️⃣: Thêm Android App (3 phút)

1. Trong Firebase Console, click biểu tượng **Android** (robot xanh lá)
2. Điền thông tin:
   ```
   Android package name: com.example.appdocu1
   App nickname: Trao Đổi Đồ Cũ
   Debug signing SHA-1: [Để trống]
   ```
3. Click **"Register app"**

✅ **Hoàn thành Bước 2**

---

### Bước 3️⃣: Tải google-services.json (QUAN TRỌNG!)

1. Click nút **"Download google-services.json"**
2. File sẽ được tải về máy bạn (thường trong thư mục Downloads)
3. **DI CHUYỂN** file này vào thư mục:
   ```
   C:\Users\Yen\OneDrive\Desktop\doanchuyennganh\appdocu1\android\app\
   ```
4. Đảm bảo file có tên chính xác: **`google-services.json`**

> **Lưu ý**: Bạn có thể kéo thả file vào VS Code để dễ dàng hơn!

✅ **Hoàn thành Bước 3** - Sau khi đặt file xong, click "Next" trong Firebase Console

---

### Bước 4️⃣: Enable Authentication (2 phút)

1. Trong Firebase Console menu bên trái, chọn **"Build"** → **"Authentication"**
2. Click nút **"Get started"**
3. Chọn tab **"Sign-in method"**
4. Click vào **"Email/Password"**
5. Bật toggle **"Enable"** (cái đầu tiên)
6. Click **"Save"**

✅ **Hoàn thành Bước 4**

---

### Bước 5️⃣: Tạo Firestore Database (2 phút)

1. Trong menu bên trái, chọn **"Build"** → **"Firestore Database"**
2. Click **"Create database"**
3. Chọn **"Start in test mode"** (để dễ test)
4. Click **"Next"**
5. Location: Chọn **`asia-southeast1 (Singapore)`**
6. Click **"Enable"**
7. Đợi 30 giây để database khởi tạo

✅ **Hoàn thành Bước 5**

---

### Bước 6️⃣: Tạo Storage (2 phút)

1. Trong menu bên trái, chọn **"Build"** → **"Storage"**
2. Click **"Get started"**
3. Chọn **"Start in test mode"**
4. Click **"Next"**
5. Location: Giữ nguyên **`asia-southeast1`**
6. Click **"Done"**

✅ **Hoàn thành Bước 6**

---

### Bước 7️⃣: Cấu hình Firestore Rules (1 phút)

1. Vẫn ở Firestore Database, chọn tab **"Rules"**
2. Copy và paste đoạn code sau:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

3. Click **"Publish"**

> **Lưu ý**: Rules này cho phép tất cả mọi người đọc/ghi (CHỈ DÙNG CHO TEST!)

✅ **Hoàn thành Bước 7**

---

### Bước 8️⃣: Cấu hình Storage Rules (1 phút)

1. Trong Storage, chọn tab **"Rules"**
2. Copy và paste:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.time < timestamp.date(2025, 12, 31);
    }
  }
}
```

3. Click **"Publish"**

✅ **Hoàn thành Bước 8**

---

## 🚀 Bước 9️⃣: Chạy ứng dụng!

Sau khi hoàn thành TẤT CẢ các bước trên, mở Terminal và chạy:

```bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

## 🎯 CHECKLIST - Đảm bảo bạn đã làm:

- [ ] Tạo Firebase Project
- [ ] Thêm Android App với package `com.example.appdocu1`
- [ ] **Tải và đặt file `google-services.json` vào `android/app/`**
- [ ] Enable Email/Password Authentication
- [ ] Tạo Firestore Database (test mode)
- [ ] Tạo Storage (test mode)
- [ ] Cấu hình Firestore Rules
- [ ] Cấu hình Storage Rules

---

## ❓ Gặp vấn đề?

### Lỗi: "google-services.json is missing"
→ Đảm bảo file `google-services.json` nằm trong `android/app/`

### Lỗi: "Default FirebaseApp is not initialized"
→ Chạy `flutter clean` và `flutter pub get` rồi chạy lại

### Ứng dụng crash ngay khi mở
→ Kiểm tra lại package name phải là `com.example.appdocu1`

### Không thể đăng ký/đăng nhập
→ Đảm bảo đã enable Email/Password trong Authentication

---

## 📝 Sau khi app chạy thành công:

1. Đăng ký tài khoản đầu tiên trong app
2. Vào Firebase Console → Firestore → Collection `users`
3. Tìm user vừa tạo → Thêm field `isAdmin: true` để có quyền admin

---

## 🎉 CHÚC MỪNG!

Nếu bạn thấy màn hình đăng nhập, có nghĩa là bạn đã cấu hình thành công! 🎊
