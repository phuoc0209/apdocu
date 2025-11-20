-- ============================================
-- Migration: Thêm cột images vào bảng products
-- Chạy file này nếu bảng products đã tồn tại
-- ============================================

USE appdocu_db;

-- Thêm cột images nếu chưa có
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS images JSON DEFAULT NULL COMMENT 'Danh sách ảnh dạng JSON array, tối đa 10 ảnh';

-- Cập nhật dữ liệu cũ: chuyển image_url thành images JSON
UPDATE products 
SET images = JSON_ARRAY(image_url)
WHERE images IS NULL AND image_url IS NOT NULL AND image_url != '';

