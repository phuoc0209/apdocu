-- ============================================
-- Migration: Cập nhật database cho các chức năng mới
-- Chạy file này nếu database đã tồn tại
-- ============================================

USE appdocu_db;

-- Thêm cột wallet_balance vào users nếu chưa có
ALTER TABLE users
ADD COLUMN IF NOT EXISTS wallet_balance DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Số dư ví (VNĐ)' AFTER avatar_url;

-- Thêm cột role vào users nếu chưa có
ALTER TABLE users
ADD COLUMN IF NOT EXISTS role ENUM('user', 'admin') DEFAULT 'user' COMMENT 'Vai trò: user hoặc admin' AFTER wallet_balance;

-- Thêm cột status vào products nếu chưa có
ALTER TABLE products
ADD COLUMN IF NOT EXISTS status ENUM('active', 'sold', 'deleted') DEFAULT 'active' COMMENT 'Trạng thái: active, sold, deleted' AFTER seller_email;

-- Tạo bảng favorites nếu chưa có
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

-- Tạo bảng reports nếu chưa có
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

-- Tạo bảng wallet_transactions nếu chưa có
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

