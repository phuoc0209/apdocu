# Hướng dẫn sửa lỗi "Access denied" khi kết nối MySQL

## Lỗi: `Error 1045 (28000): Access denied for user 'root'@'localhost'`

Lỗi này xảy ra khi mật khẩu MySQL không khớp với cấu hình trong code.

## Cách kiểm tra và sửa lỗi

### Bước 1: Kiểm tra mật khẩu MySQL của bạn

#### Cách 1: Kiểm tra qua phpMyAdmin
1. Mở trình duyệt và truy cập: `http://localhost/phpmyadmin`
2. Nếu bạn có thể đăng nhập **KHÔNG CẦN** nhập mật khẩu → MySQL của bạn **KHÔNG CÓ** mật khẩu
3. Nếu bạn **PHẢI** nhập mật khẩu → Ghi nhớ mật khẩu đó

#### Cách 2: Kiểm tra qua XAMPP
1. Mở XAMPP Control Panel
2. Nhấn nút "Admin" bên cạnh MySQL
3. Nếu mở được phpMyAdmin ngay → MySQL **KHÔNG CÓ** mật khẩu
4. Nếu yêu cầu đăng nhập → MySQL **CÓ** mật khẩu

### Bước 2: Cập nhật cấu hình trong code

Mở file: `lib/models/database_config.dart`

#### Trường hợp 1: MySQL KHÔNG CÓ mật khẩu
```dart
static const String password = '';  // Để trống
```

#### Trường hợp 2: MySQL CÓ mật khẩu
```dart
static const String password = 'mat_khau_cua_ban';  // Thay bằng mật khẩu thực tế
```

Ví dụ nếu mật khẩu của bạn là `123456`:
```dart
static const String password = '123456';
```

### Bước 3: Khởi động lại ứng dụng

Sau khi sửa, khởi động lại ứng dụng Flutter:
```bash
flutter run
```

## Các trường hợp khác

### Nếu vẫn không kết nối được:

1. **Kiểm tra MySQL đã khởi động chưa:**
   - Mở XAMPP Control Panel
   - Đảm bảo MySQL đang chạy (màu xanh)

2. **Kiểm tra port:**
   - Mặc định MySQL chạy trên port 3306
   - Nếu bạn đã thay đổi port, cập nhật trong `database_config.dart`

3. **Kiểm tra database đã tồn tại chưa:**
   - Mở phpMyAdmin
   - Kiểm tra xem database `appdocu_db` đã được tạo chưa
   - Nếu chưa, import file `database.sql`

4. **Reset mật khẩu MySQL (nếu cần):**
   - Mở Command Prompt với quyền Administrator
   - Dừng MySQL trong XAMPP
   - Chạy lệnh:
     ```bash
     cd C:\xampp\mysql\bin
     mysqld --skip-grant-tables
     ```
   - Mở Command Prompt mới và chạy:
     ```bash
     mysql -u root
     ```
   - Trong MySQL console:
     ```sql
     USE mysql;
     UPDATE user SET password='' WHERE user='root';
     FLUSH PRIVILEGES;
     EXIT;
     ```
   - Khởi động lại MySQL trong XAMPP

## Lưu ý bảo mật

⚠️ **Không nên để mật khẩu trống trong môi trường production!**

Trong production, bạn nên:
1. Tạo user MySQL riêng cho ứng dụng (không dùng root)
2. Cấp quyền hạn chế cho user đó
3. Sử dụng mật khẩu mạnh
4. Lưu mật khẩu trong biến môi trường hoặc file cấu hình an toàn

