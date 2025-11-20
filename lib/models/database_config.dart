// Database configuration helper
class DatabaseConfig {
  DatabaseConfig._();

  // Cấu hình MySQL cho XAMPP
  static const String host = 'localhost';
  static const int port = 3306;
  static const String database = 'appdocu_db';
  static const String user = 'root';
  static const String password = '';

  // Cấu hình API backend (nếu sử dụng HTTP API thay vì kết nối trực tiếp)
  static const String apiBaseUrl = 'http://localhost/appdocu_api';
  
  static const int maxConnections = 10;

  static String get connectionUrl => 'mysql://$user:$password@$host:$port/$database';

  static bool get isValidConfig => host.isNotEmpty && database.isNotEmpty && user.isNotEmpty;

  static const String setupInstructions = '''
Cấu hình database cho XAMPP:

1. Mở XAMPP Control Panel và khởi động MySQL
2. Mở phpMyAdmin (http://localhost/phpmyadmin)
3. Import file database.sql để tạo database và các bảng
4. Kiểm tra thông tin kết nối:
   - host: localhost
   - port: 3306
   - database: appdocu_db
   - user: root
   - password: (để trống mặc định)

⚠️ NẾU GẶP LỖI "Access denied":
   - Nếu MySQL của bạn CÓ mật khẩu: Cập nhật password ở dòng 10
   - Nếu MySQL của bạn KHÔNG có mật khẩu: Để password = '' (rỗng)
   - Kiểm tra mật khẩu MySQL bằng cách đăng nhập phpMyAdmin

Thay đổi các giá trị trên trong DatabaseConfig nếu cần.
''';

}
