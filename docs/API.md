# 🌐 TÀI LIỆU REST API - CỬA HÀNG MÁY TÍNH (COMPUTER STORE)

**Học phần:** Lập trình thiết bị di động  
**Backend:** ASP.NET Core 8.0 Web API  
**Base URL Mặc định:** `https://oldorangeapple30.conveyor.cloud/` (được cấu hình tập trung tại `lib/core/config/app_config.dart`, có thể đổi trực tiếp trong app hoặc qua `--dart-define=BASE_URL=...`)  
**Định dạng dữ liệu:** JSON, camelCase  
**Chuẩn xử lý lỗi:** RFC 7807 ProblemDetails

---

## ⚠️ 1. ĐỊNH DẠNG LỖI (RFC 7807 ProblemDetails)
Khi xảy ra lỗi (4xx, 5xx), máy chủ trả về JSON dạng:
```json
{
  "type": "https://tools.ietf.org/html/rfc7231#section-6.5.1",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "code": "EMAIL_NOT_VERIFIED",
  "detail": "Email chưa được kích hoạt. Vui lòng xác thực mã OTP.",
  "errors": {
    "Email": ["Email không đúng định dạng."],
    "Password": ["Mật khẩu tối thiểu 6 ký tự."]
  }
}
```

Mã lỗi đặc biệt:
- `EMAIL_NOT_VERIFIED`: Email chưa xác thực OTP. Ứng dụng tự động điều hướng sang màn hình Nhập OTP.
- `INVALID_CREDENTIALS`: Sai tài khoản hoặc mật khẩu.
- `ACCOUNT_LOCKED`: Tài khoản bị khóa.
- `OTP_EXPIRED`: Mã OTP đã hết hạn.
- `OTP_INVALID`: Mã OTP không chính xác.

---

## 🔐 2. XÁC THỰC & TÀI KHOẢN (`/api/auth` & `/api/me`)

### 2.1 Đăng ký tài khoản (`POST /api/auth/register`)
- **Request Body:**
```json
{
  "fullName": "Nguyễn Y Phi",
  "email": "phi@example.com",
  "password": "Password123@",
  "confirmPassword": "Password123@"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Đăng ký thành công! Vui lòng kiểm tra email để lấy mã OTP xác thực.",
  "email": "phi@example.com"
}
```

### 2.2 Xác thực OTP kích hoạt tài khoản (`POST /api/auth/verify-otp` hoặc `/api/auth/verify-email`)
- **Request Body:**
```json
{
  "email": "phi@example.com",
  "otpCode": "123456"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Kích hoạt tài khoản thành công! Bạn có thể đăng nhập ngay bây giờ."
}
```

### 2.3 Gửi lại mã OTP (`POST /api/auth/resend-otp`)
- **Request Body:**
```json
{
  "email": "phi@example.com"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Mã OTP mới đã được gửi vào hòm thư của bạn."
}
```

### 2.4 Đăng nhập (`POST /api/auth/login`)
- **Request Body:**
```json
{
  "email": "phi@example.com",
  "password": "Password123@"
}
```
- **Response 200 OK:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
  "refreshToken": "mIvDowifJr6nG6GqCfuHMPFR...",
  "expiresAt": "2026-10-30T18:00:00Z",
  "user": {
    "userId": 1,
    "fullName": "Nguyễn Y Phi",
    "email": "phi@example.com",
    "role": "Customer"
  }
}
```
- **Response 400 (Chưa xác thực email):**
```json
{
  "code": "EMAIL_NOT_VERIFIED",
  "title": "Email chưa được kích hoạt",
  "detail": "Vui lòng nhập mã OTP để kích hoạt tài khoản."
}
```

### 2.5 Quên mật khẩu (`POST /api/auth/forgot-password`)
- **Request Body:**
```json
{
  "email": "phi@example.com"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Mã OTP đặt lại mật khẩu đã được gửi đến email."
}
```

### 2.6 Đặt lại mật khẩu (`POST /api/auth/reset-password`)
- **Request Body:**
```json
{
  "email": "phi@example.com",
  "otpCode": "123456",
  "newPassword": "NewPassword123@",
  "confirmPassword": "NewPassword123@"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại."
}
```

### 2.7 Thông tin tài khoản hiện tại (`GET /api/me`)
- **Header:** `Authorization: Bearer <accessToken>`
- **Response 200 OK:**
```json
{
  "userId": 1,
  "fullName": "Nguyễn Y Phi",
  "email": "phi@example.com",
  "role": "Customer",
  "phoneNumber": "0388166999",
  "isActive": true
}
```

### 2.8 Đăng xuất (`POST /api/auth/logout`)
- **Header:** `Authorization: Bearer <accessToken>`
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Đăng xuất thành công."
}
```

---

## 💻 3. DANH MỤC & SẢN PHẨM (`/api/categories` & `/api/products`)

### 3.1 Danh sách danh mục (`GET /api/categories`)
- **Response 200 OK:**
```json
[
  {
    "categoryId": 1,
    "categoryName": "Laptop",
    "productCount": 24
  },
  {
    "categoryId": 2,
    "categoryName": "PC & Máy trạm",
    "productCount": 18
  },
  {
    "categoryId": 3,
    "categoryName": "Linh kiện máy tính",
    "productCount": 45
  },
  {
    "categoryId": 4,
    "categoryName": "Màn hình",
    "productCount": 12
  },
  {
    "categoryId": 5,
    "categoryName": "Bàn phím & Chuột",
    "productCount": 30
  }
]
```

### 3.2 Lưới sản phẩm phân trang (`GET /api/products`)
- **Query Params:**
  - `categoryId`: Lọc theo ID danh mục (int, optional)
  - `q`: Từ khóa tìm kiếm (string, optional)
  - `page`: Trang hiện tại (int, default 1)
  - `pageSize`: Số sản phẩm mỗi trang (int, default 10)
- **Response 200 OK:**
```json
{
  "items": [
    {
      "productId": 1,
      "productName": "Laptop Gaming ASUS ROG Zephyrus G14",
      "price": 38990000,
      "discountPercent": 10,
      "finalPrice": 35091000,
      "quantity": 15,
      "imageUrl": "https://example.com/images/rog-g14.jpg",
      "categoryId": 1,
      "categoryName": "Laptop"
    }
  ],
  "totalItems": 50,
  "page": 1,
  "pageSize": 10,
  "totalPages": 5
}
```
*(Nếu server trả mảng danh sách trực tiếp, ứng dụng cũng tự động tương thích)*

### 3.3 Chi tiết sản phẩm (`GET /api/products/{id}`)
- **Response 200 OK:**
```json
{
  "productId": 1,
  "productName": "Laptop Gaming ASUS ROG Zephyrus G14 GA402RJ",
  "price": 38990000,
  "discountPercent": 10,
  "finalPrice": 35091000,
  "quantity": 15,
  "description": "Laptop gaming mỏng nhẹ hiệu năng vượt trội với màn hình chuẩn màu Nebula Display và vi xử lý AMD Ryzen thế hệ mới...",
  "imageUrl": "https://example.com/images/rog-g14.jpg",
  "additionalImages": "https://example.com/images/g14-2.jpg,https://example.com/images/g14-3.jpg",
  "categoryId": 1,
  "category": {
    "categoryId": 1,
    "categoryName": "Laptop"
  },
  "productColors": [
    {
      "id": 1,
      "productId": 1,
      "colorName": "Trắng Moonlight White",
      "colorCode": "#F5F5F5",
      "quantity": 10,
      "imageUrl": "https://example.com/images/rog-g14-white.jpg"
    },
    {
      "id": 2,
      "productId": 1,
      "colorName": "Xám Eclipse Gray",
      "colorCode": "#333333",
      "quantity": 5,
      "imageUrl": "https://example.com/images/rog-g14-gray.jpg"
    }
  ],
  "specGroups": [
    {
      "id": 1,
      "name": "Bộ xử lý (CPU)",
      "displayOrder": 1,
      "specKeys": [
        { "name": "Công nghệ CPU", "value": "AMD Ryzen 7 6800HS" },
        { "name": "Số nhân / Luồng", "value": "8 nhân 16 luồng" },
        { "name": "Tốc độ tối đa", "value": "4.7 GHz" }
      ]
    },
    {
      "id": 2,
      "name": "Bộ nhớ RAM & Ổ cứng",
      "displayOrder": 2,
      "specKeys": [
        { "name": "Dung lượng RAM", "value": "16 GB DDR5 4800MHz" },
        { "name": "Ổ cứng", "value": "1 TB SSD M.2 PCIe Gen 4" }
      ]
    },
    {
      "id": 3,
      "name": "Màn hình & Đồ họa",
      "displayOrder": 3,
      "specKeys": [
        { "name": "Kích thước màn hình", "value": "14 inch WQXGA (2560 x 1600)" },
        { "name": "Tần số quét", "value": "120Hz" },
        { "name": "Card đồ họa", "value": "AMD Radeon RX 6700S 8GB" }
      ]
    }
  ]
}
```

---

## 📦 4. ĐƠN HÀNG & THANH TOÁN (`/api/orders`)

Tất cả các API đơn hàng đều yêu cầu Header:
```http
Authorization: Bearer <access_token>
```

### 4.1 Tạo đơn hàng mới (`POST /api/orders`)
- **Mô tả:** Đặt hàng từ danh sách sản phẩm trong giỏ. Máy chủ sẽ tự động tính toán lại giá, kiểm tra tồn kho và phiên bản bản ghi (concurrency).
- **Request Body:**
```json
{
  "fullName": "Nguyễn Y Phi",
  "phone": "0388166999",
  "address": "123 Nguyễn Văn Cừ, Q.5, TP.HCM",
  "paymentMethod": "QR",
  "voucherCode": "GIAM10",
  "items": [
    {
      "productId": 1,
      "colorId": 1,
      "quantity": 2
    }
  ]
}
```
*Các giá trị `paymentMethod` hợp lệ: `"COD"` (Thanh toán khi nhận hàng) hoặc `"QR"` (Thanh toán mã QR chuyển khoản).*

- **Response 201 Created / 200 OK:**
```json
{
  "orderId": 101,
  "orderDate": "2026-10-29T20:50:00Z",
  "totalPrice": 70182000,
  "status": "Pending",
  "fullName": "Nguyễn Y Phi",
  "phone": "0388166999",
  "address": "123 Nguyễn Văn Cừ, Q.5, TP.HCM",
  "paymentMethod": "QR",
  "paymentStatus": "Pending",
  "orderDetails": [
    {
      "orderDetailId": 1,
      "productId": 1,
      "productName": "Laptop Gaming ASUS ROG Zephyrus G14",
      "imageUrl": "https://example.com/images/rog-g14.jpg",
      "colorName": "Trắng Moonlight White",
      "quantity": 2,
      "price": 35091000,
      "finalPrice": 35091000
    }
  ]
}
```

- **Mã lỗi đặc biệt:**
  - `409 Conflict` (`CONCURRENCY_CONFLICT`): Báo `"Sản phẩm vừa thay đổi/hết hàng, vui lòng kiểm tra lại giỏ hàng"`.
  - `400 Bad Request`: Thiếu thông tin hoặc vượt quá tồn kho hiện tại.

---

### 4.2 Lấy thông tin thanh toán QR (`GET /api/orders/{id}/payment-qr`)
- **Mô tả:** Lấy thông tin chuyển khoản ngân hàng và đường dẫn mã VietQR động theo đơn hàng.
- **Response 200 OK:**
```json
{
  "orderId": 101,
  "qrImageUrl": "https://img.vietqr.io/image/970422-0388166999-compact2.png?amount=70182000&addInfo=DH101",
  "amount": 70182000,
  "transferContent": "DH101",
  "bankName": "MBBank (Ngân hàng Quân Đội)",
  "accountNumber": "0388166999",
  "accountName": "NGUYEN Y PHI",
  "status": "Pending",
  "paymentStatus": "Pending"
}
```

---

### 4.3 Danh sách đơn hàng của người dùng (`GET /api/orders`)
- **Mô tả:** Lấy lịch sử tất cả đơn hàng mà người dùng đã đặt, sắp xếp mới nhất lên đầu.
- **Response 200 OK:**
```json
[
  {
    "orderId": 101,
    "orderDate": "2026-10-29T20:50:00Z",
    "totalPrice": 70182000,
    "status": "Pending",
    "paymentMethod": "QR",
    "paymentStatus": "Pending",
    "itemCount": 2
  }
]
```

*Các trạng thái `status`:*
- `Pending`: Chờ xác nhận
- `Processing`: Đang xử lý
- `Shipped`: Đang giao hàng
- `Delivered`: Đã giao hàng
- `Cancelled`: Đã hủy

---

### 4.4 Chi tiết đơn hàng (`GET /api/orders/{id}`)
- **Mô tả:** Lấy toàn bộ thông tin chi tiết đơn hàng kèm danh sách chi tiết các sản phẩm đã mua (`orderDetails`).
- **Response 200 OK:**
```json
{
  "orderId": 101,
  "orderDate": "2026-10-29T20:50:00Z",
  "totalPrice": 70182000,
  "status": "Pending",
  "fullName": "Nguyễn Y Phi",
  "phone": "0388166999",
  "address": "123 Nguyễn Văn Cừ, Q.5, TP.HCM",
  "paymentMethod": "QR",
  "paymentStatus": "Pending",
  "orderDetails": [
    {
      "orderDetailId": 1,
      "productId": 1,
      "productName": "Laptop Gaming ASUS ROG Zephyrus G14",
      "imageUrl": "https://example.com/images/rog-g14.jpg",
      "colorName": "Trắng Moonlight White",
      "colorCode": "#F5F5F5",
      "quantity": 2,
      "price": 35091000,
      "finalPrice": 35091000
    }
  ]
}
```

