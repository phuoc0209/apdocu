# Hướng dẫn cài đặt Database cho AppDocu

## Yêu cầu
- XAMPP đã được cài đặt
- Flutter SDK đã được cài đặt

## Các bước cài đặt

### 1. Khởi động MySQL trong XAMPP
1. Mở XAMPP Control Panel
2. Nhấn nút "Start" cho MySQL
3. Đảm bảo MySQL đang chạy (màu xanh)

### 2. Tạo Database
1. Mở trình duyệt và truy cập: `http://localhost/phpmyadmin`
2. Chọn tab "SQL" ở trên cùng
3. Mở file `database.sql` trong thư mục gốc của project
4. Copy toàn bộ nội dung và paste vào khung SQL trong phpMyAdmin
5. Nhấn nút "Go" để thực thi

Hoặc bạn có thể:
- Chọn tab "Import" trong phpMyAdmin
- Chọn file `database.sql`
- Nhấn "Go" để import

### 3. Kiểm tra Database
Sau khi import thành công, bạn sẽ thấy:
- Database: `appdocu_db`
- Bảng: `users`, `products`, `login_history`
- Dữ liệu mẫu đã được thêm vào

### 4. Cấu hình kết nối
File `lib/models/database_config.dart` đã được cấu hình mặc định:
- Host: `localhost`
- Port: `3306`
- Database: `appdocu_db`
- User: `root`
- Password: (để trống)

Nếu bạn đã thay đổi mật khẩu root của MySQL, hãy cập nhật trong file `database_config.dart`.

### 5. Cài đặt dependencies
Chạy lệnh sau trong terminal:
```bash
flutter pub get
```

### 6. Chạy ứng dụng
```bash
flutter run
```

## Lưu ý quan trọng

⚠️ **Bảo mật mật khẩu:**
- Hiện tại code sử dụng hash password đơn giản
- Trong production, nên sử dụng package `bcrypt` để hash mật khẩu an toàn hơn
- Cập nhật các hàm `_hashPassword()` và `_verifyPassword()` trong `database_service.dart`

⚠️ **Kết nối từ Flutter:**
- Package `mysql1` hoạt động tốt trên server-side Dart
- Đối với Flutter mobile app, bạn có thể cần tạo backend API (PHP/Node.js) để kết nối MySQL
- Hoặc sử dụng HTTP package để gọi API backend

## Cấu trúc Database

### Bảng Users
- `id`: ID người dùng (auto increment)
- `username`: Tên đăng nhập (unique)
- `password`: Mật khẩu đã hash
- `email`: Email (unique)
- `phone`: Số điện thoại
- `full_name`: Tên đầy đủ
- `avatar_url`: URL avatar
- `created_at`: Thời gian tạo
- `updated_at`: Thời gian cập nhật
- `is_active`: Trạng thái hoạt động

### Bảng Products
- `id`: ID sản phẩm (auto increment)
- `title`: Tên sản phẩm
- `description`: Mô tả
- `price`: Giá
- `image_url`: URL hình ảnh
- `category`: Danh mục
- `seller_id`: ID người bán (FK)
- `seller_name`: Tên người bán
- `seller_phone`: SĐT người bán
- `seller_email`: Email người bán
- `created_at`: Thời gian tạo
- `updated_at`: Thời gian cập nhật
- `is_active`: Trạng thái hoạt động

### Bảng Login History
- `id`: ID bản ghi (auto increment)
- `user_id`: ID người dùng (FK)
- `login_time`: Thời gian đăng nhập
- `ip_address`: Địa chỉ IP
- `device_info`: Thông tin thiết bị
- `login_method`: Phương thức đăng nhập (email/google/facebook)

## Xử lý lỗi thường gặp

### Lỗi: "Không thể kết nối database"
- Kiểm tra MySQL đã khởi động trong XAMPP chưa
- Kiểm tra port 3306 có bị chiếm dụng không
- Kiểm tra thông tin kết nối trong `database_config.dart`

### Lỗi: "Access denied for user"
- Kiểm tra username và password trong `database_config.dart`
- Đảm bảo user có quyền truy cập database `appdocu_db`

### Lỗi: "Table doesn't exist"
- Chạy lại file `database.sql` để tạo các bảng
- Kiểm tra database `appdocu_db` đã được tạo chưa

