# Kiểm tra Firebase Storage

## Lỗi: "Upload took too long" 

### Nguyên nhân có thể:

1. **Firebase Storage chưa được enable**
2. **Storage Rules chặn upload**
3. **Ảnh quá lớn**
4. **Chưa cấu hình CORS cho web**

---

## BƯỚC 1: Enable Firebase Storage

1. Vào https://console.firebase.google.com
2. Chọn project của bạn
3. Bên trái chọn **Build** > **Storage**
4. Nếu chưa enable, click **Get started**
5. Chọn location gần nhất (ví dụ: asia-southeast1)
6. Click **Done**

---

## BƯỚC 2: Cấu hình Storage Rules

1. Trong **Storage**, click tab **Rules**
2. Copy và paste rules này:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    // Allow all to read
    match /{allPaths=**} {
      allow read: if true;
    }
    
    // Profile images - authenticated users only
    match /profiles/{fileName} {
      allow write: if request.auth != null && 
                     request.resource.size < 10 * 1024 * 1024;
    }
    
    // Product images - authenticated users only  
    match /products/{allPaths=**} {
      allow write: if request.auth != null &&
                     request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

3. Click **Publish**

---

## BƯỚC 3: Kiểm tra trong Console

1. Mở Chrome DevTools (F12)
2. Vào tab **Console**
3. Thử upload ảnh
4. Xem log:
   - Nếu thấy "Starting profile image upload..." → Code chạy OK
   - Nếu thấy timeout → Firebase Storage có vấn đề
   - Nếu thấy "403 Forbidden" → Rules chặn
   - Nếu thấy "401 Unauthorized" → Chưa đăng nhập

---

## BƯỚC 4: Test với ảnh nhỏ

1. Chọn ảnh < 500KB
2. Upload
3. Nếu thành công → vấn đề là ảnh quá lớn
4. Nếu vẫn fail → vấn đề là Firebase config

---

## BƯỚC 5: Kiểm tra Network

1. DevTools > **Network** tab
2. Filter: **Fetch/XHR**
3. Upload ảnh
4. Click vào request upload
5. Xem:
   - **Status**: 200 = OK, 403 = Forbidden, 0 = Network error
   - **Response**: Chi tiết lỗi
   - **Time**: Thời gian upload

---

## Nếu vẫn lỗi:

### Option 1: Check CORS (cho Web)

Firebase Storage cần CORS configuration cho web. Run:

```bash
gsutil cors set cors.json gs://YOUR-PROJECT-ID.appspot.com
```

File `cors.json`:
```json
[
  {
    "origin": ["http://localhost:54204"],
    "method": ["GET", "POST", "PUT", "DELETE"],
    "maxAgeSeconds": 3600
  }
]
```

### Option 2: Thử mode test (KHÔNG an toàn - chỉ để test)

Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if true;  // CHỈ ĐỂ TEST!
    }
  }
}
```

Nếu work → vấn đề là rules
Nếu vẫn fail → vấn đề là config hoặc network

---

## Debug Info

Khi upload, code sẽ log:
```
Starting profile image upload...
Profile image size: 1234567 bytes (1.18 MB)
Uploading to Firebase Storage...
[Nếu success]: Getting download URL...
[Nếu success]: Profile image uploaded successfully: https://...
[Nếu fail]: Upload profile image error: ...
```

Gửi cho mình toàn bộ log trong Console để debug!
