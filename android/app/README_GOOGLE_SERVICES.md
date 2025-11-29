# ⚠️ FILE GOOGLE-SERVICES.JSON CẦN ĐƯỢC ĐẶT TẠI ĐÂY

## Hướng dẫn:

1. Vào Firebase Console: https://console.firebase.google.com/
2. Chọn project của bạn
3. Click vào biểu tượng **Settings** (bánh răng) → **Project settings**
4. Scroll xuống phần **Your apps**
5. Tìm Android app với package name: `com.example.appdocu1`
6. Click nút **"Download google-services.json"**
7. Copy file đã tải vào thư mục này (`android/app/`)

## Hoặc nếu chưa thêm Android app:

1. Trong Firebase Console, click biểu tượng Android
2. Package name: `com.example.appdocu1`
3. App nickname: `Trao Đổi Đồ Cũ`
4. Click "Register app"
5. Download google-services.json
6. Đặt file vào thư mục này

## Lưu ý:
- File này chứa API keys và cấu hình Firebase
- KHÔNG commit file này lên Git public
- Mỗi project Firebase có file riêng
- App sẽ KHÔNG chạy nếu thiếu file này
