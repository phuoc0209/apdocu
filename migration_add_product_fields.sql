-- Migration: Thêm trường cho chức năng trao đổi
USE appdocu_db;

ALTER TABLE products
ADD COLUMN IF NOT EXISTS item_condition VARCHAR(50) DEFAULT NULL COMMENT 'Tình trạng sản phẩm (Mới, Cũ,...)' AFTER description,
ADD COLUMN IF NOT EXISTS item_size VARCHAR(100) DEFAULT NULL COMMENT 'Kích thước/chi tiết kích thước' AFTER item_condition,
ADD COLUMN IF NOT EXISTS exchange_reason TEXT DEFAULT NULL COMMENT 'Lý do trao đổi' AFTER item_size,
ADD COLUMN IF NOT EXISTS exchange_value DECIMAL(10,2) DEFAULT NULL COMMENT 'Giá trị quy đổi (nếu có)' AFTER exchange_reason,
ADD COLUMN IF NOT EXISTS exchange_type ENUM('swap','donate','sell') DEFAULT 'sell' COMMENT 'Hình thức trao đổi: swap, donate, sell' AFTER exchange_value;

-- Nếu cần, chạy file này để cập nhật database hiện tại.
