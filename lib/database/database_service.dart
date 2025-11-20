import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mysql1/mysql1.dart';
import '../models/database_config.dart';
import '../models/product.dart';

/// Service để kết nối và thao tác với MySQL database
class DatabaseService {
  static DatabaseService? _instance;
  MySqlConnection? _connection;

  DatabaseService._();

  /// Singleton instance
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  /// Kết nối đến database
  Future<bool> connect() async {
    try {
      // Nếu chạy trên web, short-circuit vì RawSocket không được hỗ trợ trên web
      if (kIsWeb) {
        debugPrint('⚠️ Chạy trên web — kết nối MySQL qua socket không được hỗ trợ.');
        _connection = null;
        return false;
      }
      if (_connection != null) {
        // Kiểm tra kết nối bằng cách thực hiện query đơn giản
        try {
          await _connection!.query('SELECT 1').timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );
          return true;
        } catch (e) {
          // Kết nối đã bị đóng hoặc lỗi, đóng và tạo kết nối mới
          try {
            await _connection?.close();
          } catch (_) {
            // Bỏ qua lỗi khi đóng
          }
          _connection = null;
        }
      }

      // Tạo ConnectionSettings với xử lý password
      final settings = ConnectionSettings(
        host: DatabaseConfig.host,
        port: DatabaseConfig.port,
        user: DatabaseConfig.user,
        password: DatabaseConfig.password.isEmpty ? null : DatabaseConfig.password,
        db: DatabaseConfig.database,
        timeout: const Duration(seconds: 10),
      );

      _connection = await MySqlConnection.connect(settings).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout after 10 seconds');
        },
      );
      return true;
    } on SocketException catch (e) {
      // Không in stack trace để tránh spam console
      debugPrint('⚠️ Lỗi kết nối socket: ${e.message}');
      debugPrint('📋 Hướng dẫn:');
      debugPrint('   1. Mở XAMPP Control Panel');
      debugPrint('   2. Khởi động MySQL server');
      debugPrint('   3. Kiểm tra port ${DatabaseConfig.port} có đang mở không');
      _connection = null;
      return false;
    } catch (e) {
      debugPrint('⚠️ Lỗi kết nối database: ${e.toString().split('\n').first}');
      debugPrint('📋 Kiểm tra cấu hình:');
      debugPrint('   - Host: ${DatabaseConfig.host}');
      debugPrint('   - Port: ${DatabaseConfig.port}');
      debugPrint('   - User: ${DatabaseConfig.user}');
      debugPrint('   - Password: ${DatabaseConfig.password.isEmpty ? "(để trống)" : "***"}');
      debugPrint('   - Database: ${DatabaseConfig.database}');
      _connection = null;
      return false;
    }
  }

  /// Kiểm tra kết nối database (public method)
  Future<bool> checkConnection() async {
    return await connect();
  }

  /// Buộc reconnect: đóng kết nối nếu có và thử kết nối lại
  Future<bool> reconnect() async {
    try {
      await disconnect();
    } catch (_) {}
    return await connect();
  }

  /// Đóng kết nối
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
  }

  /// Kiểm tra kết nối
  bool get isConnected => _connection != null;

  /// Đảm bảo connection còn sống trước khi query
  /// Tự động reconnect nếu connection bị đóng
  Future<bool> _ensureConnection() async {
    // Nếu chạy trên web, trả về false ngay — các phương thức phía trên sẽ xử lý fallback
    if (kIsWeb) {
      _connection = null;
      return false;
    }

    if (_connection == null) {
      return await connect();
    }
    
    // Kiểm tra connection còn sống không
    try {
      await _connection!.query('SELECT 1').timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw Exception('Connection check timeout');
        },
      );
      return true;
    } catch (e) {
      // Connection đã chết, reconnect
      try {
        await _connection?.close();
      } catch (_) {
        // Bỏ qua lỗi khi đóng
      }
      _connection = null;
      return await connect();
    }
  }

  // ============================================
  // USER OPERATIONS
  // ============================================

  /// Đăng ký user mới
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String email,
    required String phone,
    String? fullName,
  }) async {
    // Đảm bảo connection trước khi query
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      // Kiểm tra username đã tồn tại chưa
      final checkUser = await _connection!.query(
        'SELECT id FROM users WHERE username = ? OR email = ?',
        [username, email],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );

      if (checkUser.isNotEmpty) {
        return {'success': false, 'message': 'Username hoặc email đã tồn tại'};
      }

      // Hash password (trong thực tế nên dùng bcrypt)
      // Ở đây chỉ hash đơn giản, nên dùng package crypto hoặc bcrypt
      final hashedPassword = _hashPassword(password);

      // Thêm user mới
      final result = await _connection!.query(
        '''INSERT INTO users (username, password, email, phone, full_name) 
           VALUES (?, ?, ?, ?, ?)''',
        [username, hashedPassword, email, phone, fullName ?? username],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );

      // Lấy thông tin user vừa tạo
      final userResult = await _connection!.query(
        'SELECT id, username, email, phone, full_name, avatar_url FROM users WHERE id = ?',
        [result.insertId],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );

      if (userResult.isNotEmpty) {
        final user = userResult.first;
        String? avatarUrl;
        try {
          final avatarValue = user['avatar_url'];
          if (avatarValue != null) {
            if (avatarValue is String) {
              avatarUrl = avatarValue;
            } else if (avatarValue is List<int>) {
              avatarUrl = utf8.decode(avatarValue);
            } else {
              avatarUrl = avatarValue.toString();
            }
          }
        } catch (e) {
          // Bỏ qua lỗi
        }

        return {
          'success': true,
          'message': 'Đăng ký thành công',
          'user': {
            'id': user['id'],
            'username': user['username'],
            'email': user['email'],
            'phone': user['phone'],
            'fullName': user['full_name'],
            'avatar_url': avatarUrl,
          }
        };
      }

      return {'success': false, 'message': 'Lỗi khi tạo user'};
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi đăng ký: $e');
      _connection = null;
      return {'success': false, 'message': 'Lỗi kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.'};
    } catch (e) {
      // Nếu là lỗi connection, reset connection
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _connection = null;
      }
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Đăng nhập user (hỗ trợ username, email hoặc phone)
  Future<Map<String, dynamic>> loginUser({
    required String identifier, // username, email hoặc phone
    required String password,
    String? ipAddress,
    String? deviceInfo,
    String loginMethod = 'email',
  }) async {
    // Đảm bảo connection trước khi query
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database. Kiểm tra MySQL đã khởi động chưa.'};
    }

    try {
      // Tìm user theo username, email hoặc phone
      final result = await _connection!.query(
        'SELECT * FROM users WHERE (username = ? OR email = ? OR phone = ?) AND is_active = 1',
        [identifier, identifier, identifier],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );

      if (result.isEmpty) {
        return {'success': false, 'message': 'Tên đăng nhập, email hoặc mật khẩu không đúng'};
      }

      final user = result.first;
      // Xử lý password an toàn (có thể là Blob)
      String storedPassword = '';
      try {
        final passwordValue = user['password'];
        if (passwordValue != null) {
          if (passwordValue is String) {
            storedPassword = passwordValue;
          } else if (passwordValue is List<int>) {
            storedPassword = utf8.decode(passwordValue);
          } else {
            storedPassword = passwordValue.toString();
          }
        }
      } catch (e) {
        return {'success': false, 'message': 'Lỗi đọc dữ liệu mật khẩu'};
      }

      // Kiểm tra password (trong thực tế nên dùng bcrypt verify)
      if (storedPassword.isEmpty || !_verifyPassword(password, storedPassword)) {
        return {'success': false, 'message': 'Mật khẩu không đúng'};
      }

      // Lưu lịch sử đăng nhập
      try {
        await _connection!.query(
          '''INSERT INTO login_history (user_id, ip_address, device_info, login_method) 
             VALUES (?, ?, ?, ?)''',
          [user['id'], ipAddress, deviceInfo, loginMethod],
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw Exception('Query timeout');
          },
        );
      } catch (e) {
        // Bỏ qua lỗi nếu không lưu được lịch sử
        debugPrint('Không thể lưu lịch sử đăng nhập: $e');
      }

      // Xử lý avatar_url an toàn
      String? avatarUrl;
      try {
        final avatarValue = user['avatar_url'];
        if (avatarValue != null) {
          if (avatarValue is String) {
            avatarUrl = avatarValue;
          } else if (avatarValue is List<int>) {
            avatarUrl = utf8.decode(avatarValue);
          } else {
            avatarUrl = avatarValue.toString();
          }
        }
      } catch (e) {
        // Bỏ qua lỗi
      }

      // Lấy wallet_balance
      double walletBalance = 0.0;
      try {
        final walletValue = user['wallet_balance'];
        if (walletValue != null) {
          if (walletValue is num) {
            walletBalance = walletValue.toDouble();
          } else if (walletValue is String) {
            walletBalance = double.tryParse(walletValue) ?? 0.0;
          }
        }
      } catch (e) {
        // Bỏ qua
      }

      return {
        'success': true,
        'message': 'Đăng nhập thành công',
        'user': {
          'id': user['id'],
          'username': user['username'],
          'email': user['email'],
          'phone': user['phone'],
          'fullName': user['full_name'],
          'avatar_url': avatarUrl,
          'wallet_balance': walletBalance,
        }
      };
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi đăng nhập: $e');
      _connection = null;
      return {'success': false, 'message': 'Lỗi kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.'};
    } catch (e) {
      // Nếu là lỗi connection, reset connection
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _connection = null;
      }
      return {'success': false, 'message': 'Lỗi kết nối database: ${e.toString().split('\n').first}'};
    }
  }

  // ============================================
  // PRODUCT OPERATIONS
  // ============================================

  /// Lấy tất cả sản phẩm
  Future<List<Product>> getAllProducts({int? sellerId}) async {
    // Đảm bảo connection trước khi query
    final connected = await _ensureConnection();
    if (!connected) {
      return [];
    }

    try {
      String query = 'SELECT * FROM products WHERE is_active = 1';
      List<dynamic> params = [];
      
      if (sellerId != null) {
        query += ' AND seller_id = ?';
        params.add(sellerId);
      }
      
      query += ' ORDER BY created_at DESC';
      
      final results = await _connection!.query(query, params).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      ).catchError((e) {
        // Nếu query fail do connection, reset và throw lại
        if (e is SocketException || 
            e.toString().contains('connection') || 
            e.toString().contains('socket')) {
          _connection = null;
        }
        throw e;
      });

      return results.map((row) {
        // Parse images từ JSON
        List<String> imageUrls = [];
        final imagesJson = row['images'];
        if (imagesJson != null) {
          try {
            String jsonString = '';
            
            // Xử lý các kiểu dữ liệu MySQL có thể trả về
            if (imagesJson is String) {
              jsonString = imagesJson;
            } else if (imagesJson is List<int>) {
              // Blob được trả về dạng List<int> (bytes)
              // Chuyển bytes sang UTF-8 string
              try {
                jsonString = utf8.decode(imagesJson);
              } catch (e) {
                // Nếu không phải UTF-8, thử Latin-1
                jsonString = String.fromCharCodes(imagesJson);
              }
            } else if (imagesJson is List) {
              // Nếu MySQL trả về dạng List trực tiếp (không phải bytes)
              if (imagesJson.isNotEmpty && imagesJson.first is! int) {
                imageUrls = imagesJson.map((e) => e.toString()).toList();
              } else {
                // Có thể là bytes
                try {
                  jsonString = utf8.decode(imagesJson.cast<int>());
                } catch (e) {
                  jsonString = String.fromCharCodes(imagesJson.cast<int>());
                }
              }
            } else {
              // Thử convert sang String
              jsonString = imagesJson.toString();
            }
            
            // Parse JSON string nếu có
            if (jsonString.isNotEmpty && imageUrls.isEmpty) {
              jsonString = jsonString.trim();
              if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
                // Parse JSON array string
                // Loại bỏ dấu ngoặc và split
                final cleanString = jsonString.substring(1, jsonString.length - 1);
                if (cleanString.isNotEmpty) {
                  // Split và loại bỏ quotes
                  final urls = cleanString
                      .split(',')
                      .map((e) => e.trim().replaceAll('"', '').replaceAll("'", '').replaceAll('\\', ''))
                      .where((e) => e.isNotEmpty)
                      .toList();
                  imageUrls = urls;
                }
              }
            }
          } catch (e) {
            debugPrint('Lỗi parse images JSON: $e, type: ${imagesJson.runtimeType}');
            // Không in value để tránh spam console
          }
        }
        
        // Nếu không có images trong JSON, dùng image_url cũ
        String mainImageUrl = '';
        try {
          final imageUrlValue = row['image_url'];
          if (imageUrlValue != null) {
            mainImageUrl = imageUrlValue.toString();
          }
        } catch (e) {
          // Bỏ qua lỗi cast
        }
        
        if (imageUrls.isEmpty && mainImageUrl.isNotEmpty) {
          imageUrls = [mainImageUrl];
        }

        // Xử lý an toàn tất cả các field có thể là Blob
        String safeString(dynamic value, [String defaultValue = '']) {
          if (value == null) return defaultValue;
          if (value is String) return value;
          if (value is List<int>) {
            try {
              return utf8.decode(value);
            } catch (e) {
              return String.fromCharCodes(value);
            }
          }
          return value.toString();
        }

        double safeDouble(dynamic value, [double defaultValue = 0.0]) {
          if (value == null) return defaultValue;
          if (value is num) return value.toDouble();
          if (value is String) {
            return double.tryParse(value) ?? defaultValue;
          }
          return defaultValue;
        }

        return Product(
          id: row['id'].toString(),
          title: safeString(row['title']),
          description: safeString(row['description']),
          price: safeDouble(row['price']),
          imageUrl: imageUrls.isNotEmpty ? imageUrls.first : mainImageUrl,
          imageUrls: imageUrls,
          category: safeString(row['category'], 'Khác'),
          sellerName: safeString(row['seller_name']).isEmpty ? null : safeString(row['seller_name']),
          sellerPhone: safeString(row['seller_phone']).isEmpty ? null : safeString(row['seller_phone']),
          sellerEmail: safeString(row['seller_email']).isEmpty ? null : safeString(row['seller_email']),
        );
      }).toList();
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi lấy sản phẩm: $e');
      // Thử reconnect
      _connection = null;
      try {
        final connected = await connect();
        if (connected) {
          // Retry query sau khi reconnect (chỉ retry 1 lần để tránh loop)
          return getAllProducts(sellerId: sellerId);
        }
      } catch (_) {
        // Bỏ qua nếu reconnect thất bại
      }
      return [];
    } catch (e) {
      debugPrint('Lỗi lấy sản phẩm: $e');
      // Nếu là lỗi connection, thử reconnect
      if (e.toString().contains('connection') || 
          e.toString().contains('socket') ||
          e.toString().contains('timeout')) {
        _connection = null;
      }
      return [];
    }
  }

  /// Cập nhật avatar cho user
  Future<Map<String, dynamic>> updateUserAvatar({
    required int userId,
    required String avatarUrl,
  }) async {
    // Đảm bảo connection trước khi query
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      await _connection!.query(
        'UPDATE users SET avatar_url = ? WHERE id = ?',
        [avatarUrl, userId],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );

      return {
        'success': true,
        'message': 'Cập nhật avatar thành công',
      };
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi cập nhật avatar: $e');
      _connection = null;
      return {'success': false, 'message': 'Lỗi kết nối database. Vui lòng thử lại.'};
    } catch (e) {
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _connection = null;
      }
      return {'success': false, 'message': 'Lỗi cập nhật avatar: ${e.toString().split('\n').first}'};
    }
  }

  /// Thêm sản phẩm mới
  Future<Map<String, dynamic>> addProduct({
    required String title,
    required String description,
    required double price,
    List<String> imageUrls = const [],
    String category = 'Khác',
    int? sellerId,
    String? sellerName,
    String? sellerPhone,
    String? sellerEmail,
    String? itemCondition,
    String? itemSize,
    String? exchangeReason,
    double? exchangeValue,
    String? exchangeType,
  }) async {
    // Đảm bảo connection trước khi query
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      // Giới hạn tối đa 10 ảnh
      final limitedImages = imageUrls.take(10).toList();
      
      // Lấy ảnh đầu tiên làm ảnh chính (để tương thích)
      final mainImageUrl = limitedImages.isNotEmpty ? limitedImages.first : '';
      
      // Chuyển danh sách ảnh thành JSON string
      String? imagesJson;
      if (limitedImages.isNotEmpty) {
        // Tạo JSON array string
        final jsonArray = limitedImages.map((url) => '"$url"').join(',');
        imagesJson = '[$jsonArray]';
      }

      final result = await _connection!.query(
        '''INSERT INTO products (title, description, price, image_url, images, category, 
           seller_id, seller_name, seller_phone, seller_email, item_condition, item_size, exchange_reason, exchange_value, exchange_type) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          title,
          description,
          price,
          mainImageUrl,
          imagesJson,
          category,
          sellerId,
          sellerName,
          sellerPhone,
          sellerEmail,
          itemCondition,
          itemSize,
          exchangeReason,
          exchangeValue,
          exchangeType
        ],
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );

      return {
        'success': true,
        'message': 'Thêm sản phẩm thành công',
        'productId': result.insertId,
      };
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi thêm sản phẩm: $e');
      _connection = null;
      return {'success': false, 'message': 'Lỗi kết nối database. Vui lòng kiểm tra MySQL server đã khởi động chưa.'};
    } catch (e) {
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _connection = null;
      }
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Cập nhật sản phẩm
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required int sellerId, // Để kiểm tra quyền
    String? title,
    String? description,
    double? price,
    List<String>? imageUrls,
    String? category,
    String? status,
  }) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      // Kiểm tra quyền sở hữu
      final checkResult = await _connection!.query(
        'SELECT seller_id FROM products WHERE id = ? AND is_active = 1',
        [productId],
      ).timeout(const Duration(seconds: 10));

      if (checkResult.isEmpty) {
        return {'success': false, 'message': 'Sản phẩm không tồn tại'};
      }

      if (checkResult.first['seller_id'] != sellerId) {
        return {'success': false, 'message': 'Bạn không có quyền chỉnh sửa sản phẩm này'};
      }

      // Build update query
      final updates = <String>[];
      final params = <dynamic>[];

      if (title != null) {
        updates.add('title = ?');
        params.add(title);
      }
      if (description != null) {
        updates.add('description = ?');
        params.add(description);
      }
      if (price != null) {
        updates.add('price = ?');
        params.add(price);
      }
      if (category != null) {
        updates.add('category = ?');
        params.add(category);
      }
      if (status != null) {
        updates.add('status = ?');
        params.add(status);
      }
      if (imageUrls != null) {
        final limitedImages = imageUrls.take(10).toList();
        final mainImageUrl = limitedImages.isNotEmpty ? limitedImages.first : '';
        final jsonArray = limitedImages.map((url) => '"$url"').join(',');
        final imagesJson = '[$jsonArray]';
        
        updates.add('image_url = ?');
        updates.add('images = ?');
        params.add(mainImageUrl);
        params.add(imagesJson);
      }

      if (updates.isEmpty) {
        return {'success': false, 'message': 'Không có thay đổi nào'};
      }

      params.add(productId);
      final query = 'UPDATE products SET ${updates.join(', ')} WHERE id = ?';

      await _connection!.query(query, params).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Query timeout'),
      );

      return {'success': true, 'message': 'Cập nhật sản phẩm thành công'};
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi cập nhật sản phẩm: $e');
      _connection = null;
      return {'success': false, 'message': 'Lỗi kết nối database'};
    } catch (e) {
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _connection = null;
      }
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Xóa sản phẩm (soft delete)
  Future<bool> deleteProduct(int productId, {int? sellerId}) async {
    // Đảm bảo connection trước khi query
    final connected = await _ensureConnection();
    if (!connected) {
      return false;
    }

    try {
      // Nếu có sellerId, kiểm tra quyền
      if (sellerId != null) {
        final checkResult = await _connection!.query(
          'SELECT seller_id FROM products WHERE id = ? AND is_active = 1',
          [productId],
        ).timeout(const Duration(seconds: 10));

        if (checkResult.isEmpty || checkResult.first['seller_id'] != sellerId) {
          return false;
        }
      }

      await _connection!.query(
        'UPDATE products SET is_active = 0, status = "deleted" WHERE id = ?',
        [productId],
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Query timeout');
        },
      );
      return true;
    } on SocketException catch (e) {
      debugPrint('Lỗi socket khi xóa sản phẩm: $e');
      _connection = null;
      return false;
    } catch (e) {
      debugPrint('Lỗi xóa sản phẩm: $e');
      if (e.toString().contains('connection') || e.toString().contains('socket')) {
        _connection = null;
      }
      return false;
    }
  }

  // ============================================
  // FAVORITES OPERATIONS
  // ============================================

  /// Thêm sản phẩm vào yêu thích
  Future<Map<String, dynamic>> addFavorite(int userId, int productId) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      await _connection!.query(
        'INSERT INTO favorites (user_id, product_id) VALUES (?, ?)',
        [userId, productId],
      ).timeout(const Duration(seconds: 10));
      return {'success': true, 'message': 'Đã thêm vào yêu thích'};
    } catch (e) {
      if (e.toString().contains('Duplicate entry')) {
        return {'success': false, 'message': 'Sản phẩm đã có trong yêu thích'};
      }
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Xóa sản phẩm khỏi yêu thích
  Future<Map<String, dynamic>> removeFavorite(int userId, int productId) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      await _connection!.query(
        'DELETE FROM favorites WHERE user_id = ? AND product_id = ?',
        [userId, productId],
      ).timeout(const Duration(seconds: 10));
      return {'success': true, 'message': 'Đã xóa khỏi yêu thích'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Kiểm tra sản phẩm có trong yêu thích không
  Future<bool> isFavorite(int userId, int productId) async {
    final connected = await _ensureConnection();
    if (!connected) return false;

    try {
      final result = await _connection!.query(
        'SELECT id FROM favorites WHERE user_id = ? AND product_id = ?',
        [userId, productId],
      ).timeout(const Duration(seconds: 10));
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Lấy danh sách sản phẩm yêu thích
  Future<List<Product>> getFavorites(int userId) async {
    final connected = await _ensureConnection();
    if (!connected) return [];

    try {
      final results = await _connection!.query(
        '''SELECT p.* FROM products p
           INNER JOIN favorites f ON p.id = f.product_id
           WHERE f.user_id = ? AND p.is_active = 1
           ORDER BY f.created_at DESC''',
        [userId],
      ).timeout(const Duration(seconds: 15));

      return results.map((row) {
        // Parse images từ JSON (giống getAllProducts)
        List<String> imageUrls = [];
        final imagesJson = row['images'];
        if (imagesJson != null) {
          try {
            String jsonString = '';
            if (imagesJson is String) {
              jsonString = imagesJson;
            } else if (imagesJson is List<int>) {
              jsonString = utf8.decode(imagesJson);
            } else if (imagesJson is List) {
              if (imagesJson.isNotEmpty && imagesJson.first is! int) {
                imageUrls = imagesJson.map((e) => e.toString()).toList();
              } else {
                jsonString = utf8.decode(imagesJson.cast<int>());
              }
            } else {
              jsonString = imagesJson.toString();
            }

            if (jsonString.isNotEmpty && imageUrls.isEmpty) {
              if (jsonString.startsWith('[') && jsonString.endsWith(']')) {
                final cleanString = jsonString.substring(1, jsonString.length - 1);
                if (cleanString.isNotEmpty) {
                  imageUrls = cleanString
                      .split(',')
                      .map((e) => e.trim().replaceAll('"', '').replaceAll("'", '').replaceAll('\\', ''))
                      .where((e) => e.isNotEmpty)
                      .toList();
                }
              }
            }
          } catch (e) {
            // Bỏ qua lỗi parse
          }
        }

        String mainImageUrl = '';
        try {
          final imageUrlValue = row['image_url'];
          if (imageUrlValue != null) {
            mainImageUrl = imageUrlValue.toString();
          }
        } catch (e) {
          // Bỏ qua
        }

        if (imageUrls.isEmpty && mainImageUrl.isNotEmpty) {
          imageUrls = [mainImageUrl];
        }

        String safeString(dynamic value, [String defaultValue = '']) {
          if (value == null) return defaultValue;
          if (value is String) return value;
          if (value is List<int>) {
            try {
              return utf8.decode(value);
            } catch (e) {
              return String.fromCharCodes(value);
            }
          }
          return value.toString();
        }

        double safeDouble(dynamic value, [double defaultValue = 0.0]) {
          if (value == null) return defaultValue;
          if (value is num) return value.toDouble();
          if (value is String) {
            return double.tryParse(value) ?? defaultValue;
          }
          return defaultValue;
        }

        return Product(
          id: row['id'].toString(),
          title: safeString(row['title']),
          description: safeString(row['description']),
          price: safeDouble(row['price']),
          imageUrl: imageUrls.isNotEmpty ? imageUrls.first : mainImageUrl,
          imageUrls: imageUrls,
          category: safeString(row['category'], 'Khác'),
          sellerName: safeString(row['seller_name']).isEmpty ? null : safeString(row['seller_name']),
          sellerPhone: safeString(row['seller_phone']).isEmpty ? null : safeString(row['seller_phone']),
          sellerEmail: safeString(row['seller_email']).isEmpty ? null : safeString(row['seller_email']),
        );
      }).toList();
    } catch (e) {
      debugPrint('Lỗi lấy danh sách yêu thích: $e');
      return [];
    }
  }

  // ============================================
  // REPORTS OPERATIONS
  // ============================================

  /// Báo cáo sản phẩm
  Future<Map<String, dynamic>> reportProduct({
    required int productId,
    required int reporterId,
    required String reason, // 'spam', 'fake', 'inappropriate', 'other'
    String? description,
  }) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      await _connection!.query(
        'INSERT INTO reports (product_id, reporter_id, reason, description) VALUES (?, ?, ?, ?)',
        [productId, reporterId, reason, description],
      ).timeout(const Duration(seconds: 10));
      return {'success': true, 'message': 'Đã gửi báo cáo thành công'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Lấy danh sách báo cáo (cho admin)
  Future<List<Map<String, dynamic>>> getReports({String? status}) async {
    final connected = await _ensureConnection();
    if (!connected) return [];

    try {
      String query = '''SELECT r.*, p.title as product_title, u.username as reporter_name
                        FROM reports r
                        INNER JOIN products p ON r.product_id = p.id
                        INNER JOIN users u ON r.reporter_id = u.id''';
      List<dynamic> params = [];

      if (status != null) {
        query += ' WHERE r.status = ?';
        params.add(status);
      }

      query += ' ORDER BY r.created_at DESC';

      final results = await _connection!.query(query, params).timeout(
        const Duration(seconds: 15),
      );

      return results.map((row) {
        String safeString(dynamic value, [String defaultValue = '']) {
          if (value == null) return defaultValue;
          if (value is String) return value;
          if (value is List<int>) {
            try {
              return utf8.decode(value);
            } catch (e) {
              return String.fromCharCodes(value);
            }
          }
          return value.toString();
        }

        return {
          'id': row['id'],
          'product_id': row['product_id'],
          'product_title': safeString(row['product_title']),
          'reporter_id': row['reporter_id'],
          'reporter_name': safeString(row['reporter_name']),
          'reason': safeString(row['reason']),
          'description': safeString(row['description']),
          'status': safeString(row['status']),
          'admin_note': safeString(row['admin_note']),
          'created_at': row['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Lỗi lấy danh sách báo cáo: $e');
      return [];
    }
  }

  // ============================================
  // WALLET OPERATIONS
  // ============================================

  /// Lấy số dư ví
  Future<double> getWalletBalance(int userId) async {
    final connected = await _ensureConnection();
    if (!connected) return 0.0;

    try {
      final result = await _connection!.query(
        'SELECT wallet_balance FROM users WHERE id = ?',
        [userId],
      ).timeout(const Duration(seconds: 10));

      if (result.isNotEmpty) {
        final balance = result.first['wallet_balance'];
        if (balance is num) return balance.toDouble();
        if (balance is String) return double.tryParse(balance) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint('Lỗi lấy số dư ví: $e');
      return 0.0;
    }
  }

  /// Nạp tiền vào ví
  Future<Map<String, dynamic>> depositWallet({
    required int userId,
    required double amount,
    String? description,
  }) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      await _connection!.query('START TRANSACTION');

      // Lấy số dư hiện tại
      final balanceResult = await _connection!.query(
        'SELECT wallet_balance FROM users WHERE id = ? FOR UPDATE',
        [userId],
      );
      final currentBalance = (balanceResult.first['wallet_balance'] as num).toDouble();
      final newBalance = currentBalance + amount;

      // Cập nhật số dư
      await _connection!.query(
        'UPDATE users SET wallet_balance = ? WHERE id = ?',
        [newBalance, userId],
      );

      // Tạo transaction record
      await _connection!.query(
        '''INSERT INTO wallet_transactions (user_id, transaction_type, amount, balance_after, description, status)
           VALUES (?, 'deposit', ?, ?, ?, 'completed')''',
        [userId, amount, newBalance, description ?? 'Nạp tiền vào ví'],
      );

      await _connection!.query('COMMIT');
      return {'success': true, 'message': 'Nạp tiền thành công', 'balance': newBalance};
    } catch (e) {
      await _connection!.query('ROLLBACK');
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Rút tiền từ ví
  Future<Map<String, dynamic>> withdrawWallet({
    required int userId,
    required double amount,
    String? description,
  }) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      await _connection!.query('START TRANSACTION');

      // Lấy số dư hiện tại
      final balanceResult = await _connection!.query(
        'SELECT wallet_balance FROM users WHERE id = ? FOR UPDATE',
        [userId],
      );
      final currentBalance = (balanceResult.first['wallet_balance'] as num).toDouble();

      if (currentBalance < amount) {
        await _connection!.query('ROLLBACK');
        return {'success': false, 'message': 'Số dư không đủ'};
      }

      final newBalance = currentBalance - amount;

      // Cập nhật số dư
      await _connection!.query(
        'UPDATE users SET wallet_balance = ? WHERE id = ?',
        [newBalance, userId],
      );

      // Tạo transaction record
      await _connection!.query(
        '''INSERT INTO wallet_transactions (user_id, transaction_type, amount, balance_after, description, status)
           VALUES (?, 'withdraw', ?, ?, ?, 'completed')''',
        [userId, amount, newBalance, description ?? 'Rút tiền từ ví'],
      );

      await _connection!.query('COMMIT');
      return {'success': true, 'message': 'Rút tiền thành công', 'balance': newBalance};
    } catch (e) {
      await _connection!.query('ROLLBACK');
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  /// Lấy lịch sử giao dịch ví
  Future<List<Map<String, dynamic>>> getWalletTransactions(int userId, {int? limit}) async {
    final connected = await _ensureConnection();
    if (!connected) return [];

    try {
      String query = '''SELECT * FROM wallet_transactions
                        WHERE user_id = ?
                        ORDER BY created_at DESC''';
      List<dynamic> params = [userId];

      if (limit != null) {
        query += ' LIMIT ?';
        params.add(limit);
      }

      final results = await _connection!.query(query, params).timeout(
        const Duration(seconds: 15),
      );

      return results.map((row) {
        return {
          'id': row['id'],
          'transaction_type': row['transaction_type'].toString(),
          'amount': (row['amount'] as num).toDouble(),
          'balance_after': (row['balance_after'] as num).toDouble(),
          'description': row['description']?.toString(),
          'status': row['status']?.toString(),
          'created_at': row['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Lỗi lấy lịch sử giao dịch: $e');
      return [];
    }
  }

  // ============================================
  // USER PROFILE OPERATIONS
  // ============================================

  /// Cập nhật thông tin cá nhân
  Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? fullName,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    final connected = await _ensureConnection();
    if (!connected) {
      return {'success': false, 'message': 'Không thể kết nối database'};
    }

    try {
      final updates = <String>[];
      final params = <dynamic>[];

      if (fullName != null) {
        updates.add('full_name = ?');
        params.add(fullName);
      }
      if (phone != null) {
        // Kiểm tra phone đã tồn tại chưa (trừ chính user này)
        final checkPhone = await _connection!.query(
          'SELECT id FROM users WHERE phone = ? AND id != ?',
          [phone, userId],
        );
        if (checkPhone.isNotEmpty) {
          return {'success': false, 'message': 'Số điện thoại đã được sử dụng'};
        }
        updates.add('phone = ?');
        params.add(phone);
      }
      if (email != null) {
        // Kiểm tra email đã tồn tại chưa (trừ chính user này)
        final checkEmail = await _connection!.query(
          'SELECT id FROM users WHERE email = ? AND id != ?',
          [email, userId],
        );
        if (checkEmail.isNotEmpty) {
          return {'success': false, 'message': 'Email đã được sử dụng'};
        }
        updates.add('email = ?');
        params.add(email);
      }
      if (avatarUrl != null) {
        updates.add('avatar_url = ?');
        params.add(avatarUrl);
      }

      if (updates.isEmpty) {
        return {'success': false, 'message': 'Không có thay đổi nào'};
      }

      params.add(userId);
      await _connection!.query(
        'UPDATE users SET ${updates.join(', ')} WHERE id = ?',
        params,
      ).timeout(const Duration(seconds: 10));

      // Lấy thông tin user đã cập nhật
      final userResult = await _connection!.query(
        'SELECT id, username, email, phone, full_name, avatar_url, wallet_balance FROM users WHERE id = ?',
        [userId],
      );

      if (userResult.isNotEmpty) {
        final user = userResult.first;
        String? avatar;
        try {
          final avatarValue = user['avatar_url'];
          if (avatarValue != null) {
            if (avatarValue is String) {
              avatar = avatarValue;
            } else if (avatarValue is List<int>) {
              avatar = utf8.decode(avatarValue);
            } else {
              avatar = avatarValue.toString();
            }
          }
        } catch (e) {
          // Bỏ qua
        }

        return {
          'success': true,
          'message': 'Cập nhật thông tin thành công',
          'user': {
            'id': user['id'],
            'username': user['username'],
            'email': user['email'],
            'phone': user['phone'],
            'fullName': user['full_name'],
            'avatar_url': avatar,
            'wallet_balance': (user['wallet_balance'] as num).toDouble(),
          }
        };
      }

      return {'success': true, 'message': 'Cập nhật thông tin thành công'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: ${e.toString().split('\n').first}'};
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Hash password đơn giản (nên dùng bcrypt trong production)
  String _hashPassword(String password) {
    // TODO: Sử dụng package crypto hoặc bcrypt để hash password
    // Tạm thời chỉ encode đơn giản
    return password; // Thay bằng bcrypt.hash(password) trong production
  }

  /// Verify password
  bool _verifyPassword(String password, String hashedPassword) {
    // TODO: Sử dụng bcrypt để verify
    return password == hashedPassword; // Thay bằng bcrypt.verify trong production
  }
}

