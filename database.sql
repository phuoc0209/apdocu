-- ============================================
-- Database: appdocu_db
-- Mô tả: Database cho ứng dụng trao đổi mua bán đồ
-- ============================================

CREATE DATABASE IF NOT EXISTS appdocu_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE appdocu_db;

-- ============================================
-- Bảng Users: Thông tin người dùng
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    full_name VARCHAR(100),
    avatar_url VARCHAR(500) DEFAULT NULL COMMENT 'Tên file ảnh avatar',
    wallet_balance DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Số dư ví (VNĐ)',
    role ENUM('user', 'admin') DEFAULT 'user' COMMENT 'Vai trò: user hoặc admin',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng Products: Sản phẩm
-- ============================================
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    image_url VARCHAR(500) DEFAULT NULL COMMENT 'Tên file ảnh chính (giữ để tương thích)',
    images JSON DEFAULT NULL COMMENT 'Danh sách tên file ảnh dạng JSON array, tối đa 10 ảnh',
    category VARCHAR(50) DEFAULT 'Khác',
    seller_id INT DEFAULT NULL COMMENT 'ID của người bán (user_id)',
    seller_name VARCHAR(100) DEFAULT NULL,
    seller_phone VARCHAR(20) DEFAULT NULL,
    seller_email VARCHAR(100) DEFAULT NULL,
    status ENUM('active', 'sold', 'deleted') DEFAULT 'active' COMMENT 'Trạng thái: active, sold, deleted',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    INDEX idx_category (category),
    INDEX idx_seller_id (seller_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng Favorites: Sản phẩm yêu thích
-- ============================================
CREATE TABLE IF NOT EXISTS favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'ID người dùng',
    product_id INT NOT NULL COMMENT 'ID sản phẩm',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_favorite (user_id, product_id),
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng Reports: Báo cáo sản phẩm
-- ============================================
CREATE TABLE IF NOT EXISTS reports (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL COMMENT 'ID sản phẩm bị báo cáo',
    reporter_id INT NOT NULL COMMENT 'ID người báo cáo',
    reason ENUM('spam', 'fake', 'inappropriate', 'other') NOT NULL COMMENT 'Lý do báo cáo',
    description TEXT COMMENT 'Mô tả chi tiết',
    status ENUM('pending', 'reviewed', 'resolved', 'rejected') DEFAULT 'pending' COMMENT 'Trạng thái xử lý',
    admin_id INT DEFAULT NULL COMMENT 'ID admin xử lý',
    admin_note TEXT COMMENT 'Ghi chú của admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product_id (product_id),
    INDEX idx_reporter_id (reporter_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng Login History: Lịch sử đăng nhập
-- ============================================
CREATE TABLE IF NOT EXISTS login_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45) DEFAULT NULL,
    device_info VARCHAR(255) DEFAULT NULL,
    login_method VARCHAR(20) DEFAULT 'email' COMMENT 'email, google, facebook',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_login_time (login_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Bảng Wallet Transactions: Lịch sử giao dịch ví
-- ============================================
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL COMMENT 'ID người dùng',
    transaction_type ENUM('deposit', 'withdraw', 'payment', 'refund') NOT NULL COMMENT 'Loại giao dịch',
    amount DECIMAL(10, 2) NOT NULL COMMENT 'Số tiền',
    balance_after DECIMAL(10, 2) NOT NULL COMMENT 'Số dư sau giao dịch',
    description VARCHAR(255) COMMENT 'Mô tả giao dịch',
    reference_id INT DEFAULT NULL COMMENT 'ID tham chiếu (product_id, order_id, etc.)',
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_transaction_type (transaction_type),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Insert dữ liệu mẫu
-- ============================================

-- Thêm user admin mẫu
INSERT INTO users (username, password, email, phone, full_name, role, wallet_balance) VALUES
('admin', 'admin123', 'admin@example.com', '0123456789', 'Administrator', 'admin', 1000000.00)
ON DUPLICATE KEY UPDATE username=username;

-- Thêm user thường mẫu
INSERT INTO users (username, password, email, phone, full_name, wallet_balance) VALUES
('user1', 'user123', 'user1@example.com', '0987654321', 'Người dùng 1', 500000.00),
('user2', 'user123', 'user2@example.com', '0987654322', 'Người dùng 2', 300000.00)
ON DUPLICATE KEY UPDATE username=username;
