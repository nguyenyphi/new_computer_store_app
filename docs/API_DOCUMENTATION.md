# 🌐 TÀI LIỆU REST API - SMARTATTEND (`nguyenyphi_1669_API`)

**Học phần:** Lập trình thiết bị di động  
**Sinh viên thực hiện:** Nguyễn Y Phi (MSSV: 2380601669)  
**Backend:** ASP.NET Core 8.0 Web API  
**Cơ sở dữ liệu:** SQL Server 2022 Docker (`nguyenyphi_1669_DB` tại `127.0.0.1,1434`)  
**Base URL:**
- Mặc định (Conveyor): `https://oldorangeapple30.conveyor.cloud/`
- Cấu hình tập trung tại `lib/core/config/app_config.dart`, hỗ trợ `--dart-define=BASE_URL=...` và đổi trực tiếp trong app.

---

## 🔐 1. HỆ THỐNG XÁC THỰC & PHÂN QUYỀN (`/api/auth`)

Tất cả các API sau xác thực đều yêu cầu Header:
```http
Authorization: Bearer <access_token>
```

### 1.1 Đăng ký tài khoản sinh viên (`POST /api/auth/register`)
- **Mô tả:** Đăng ký tài khoản sinh viên mới. Mặc định gán vai trò `Student` (không cho phép client tự chọn vai trò `Admin` hoặc `Teacher`). Mật khẩu được băm bằng BCrypt. Hệ thống sinh mã OTP 6 chữ số có hạn 5 phút và lưu băm SHA-256.
- **Request Body:**
```json
{
  "fullName": "Nguyễn Y Phi",
  "studentCode": "2380601669",
  "email": "sv.phi@diemdanh.edu.vn",
  "username": "sv_phi_new",
  "password": "Password@123",
  "confirmPassword": "Password@123",
  "phoneNumber": "0388166999"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Đăng ký tài khoản thành công! Vui lòng nhập mã OTP gửi về email sv.***@diemdanh.edu.vn để kích hoạt.",
  "studentCode": "2380601669"
}
```

---

### 1.2 Kích hoạt tài khoản bằng OTP (`POST /api/auth/verify-email`)
- **Mô tả:** Nhập mã OTP 6 số để kích hoạt tài khoản `EmailConfirmed = true`.
- **Request Body:**
```json
{
  "username": "sv_phi_new",
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

---

### 1.3 Đăng nhập bước 1 (`POST /api/auth/login`)
- **Mô tả:** Kiểm tra Username và Password. Nếu hợp lệ, hệ thống tạo OTP 6 số (hạn 5 phút) gửi về email của người dùng và yêu cầu xác thực bước 2.
- **Request Body:**
```json
{
  "username": "sv_phi",
  "password": "SinhVien@123"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Mã xác thực OTP đã được gửi về sv.***@diemdanh.edu.vn",
  "requiresOtp": true,
  "maskedEmail": "sv.***@diemdanh.edu.vn",
  "accessToken": null,
  "refreshToken": null,
  "expiresAt": null,
  "user": {
    "id": 4,
    "fullName": "Nguyễn Y Phi",
    "email": "sv.phi@diemdanh.edu.vn",
    "username": "sv_phi",
    "role": "Student",
    "studentCode": "2380601669",
    "isActive": true,
    "emailConfirmed": true
  }
}
```

---

### 1.4 Xác thực OTP bước 2 (`POST /api/auth/verify-login-otp`)
- **Mô tả:** Kiểm tra mã OTP 6 số. Nếu đúng, cấp phát JWT Access Token (hạn 24h) và Refresh Token (hạn 7 ngày).
- **Request Body:**
```json
{
  "username": "sv_phi",
  "otpCode": "123456"
}
```
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Đăng nhập thành công!",
  "requiresOtp": false,
  "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
  "refreshToken": "mIvDowifJr6nG6GqCfuHMPFR...",
  "expiresAt": "2026-10-22T01:42:14Z",
  "user": {
    "id": 4,
    "fullName": "Nguyễn Y Phi",
    "email": "sv.phi@diemdanh.edu.vn",
    "username": "sv_phi",
    "role": "Student",
    "studentCode": "2380601669"
  }
}
```

---

### 1.5 Làm mới Access Token (`POST /api/auth/refresh`)
- **Request Body:**
```json
{
  "refreshToken": "mIvDowifJr6nG6GqCfuHMPFR..."
}
```
- **Response 200 OK:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
  "refreshToken": "new_refresh_token_...",
  "expiresAt": "2026-10-22T08:00:00Z"
}
```

---

### 1.6 Đăng xuất (`POST /api/auth/logout`)
- **Header:** `Authorization: Bearer <token>`
- **Mô tả:** Thu hồi toàn bộ Refresh Token của người dùng.

---

## 🏛️ 2. QUẢN LÝ HỌC THUẬT & CRUD

### 2.1 Quản lý Môn học (`/api/subjects`)
- `GET /api/subjects`: Danh sách môn học (kèm số tín chỉ, số lớp học).
- `POST /api/subjects` *(Admin)*: Tạo môn học mới.
- `PUT /api/subjects/{id}` *(Admin)*: Cập nhật môn học.
- `DELETE /api/subjects/{id}` *(Admin)*: Xóa môn học (kiểm tra ràng buộc lớp học).

### 2.2 Quản lý Lớp học phần (`/api/classes`)
- `GET /api/classes`: Lấy danh sách lớp học (Sinh viên chỉ xem lớp mình học; Giảng viên xem lớp được phân công; Admin xem toàn bộ).
- `POST /api/classes` *(Admin)*: Tạo lớp học phần mới (bao gồm tọa độ GPS phòng học, bán kính cho phép ví dụ 50m).
- `PUT /api/classes/{id}` *(Admin)*: Cập nhật thông tin phòng, giảng viên phụ trách, vị trí địa lý.
- `DELETE /api/classes/{id}` *(Admin)*: Xóa lớp học phần.
- `POST /api/classes/{id}/enroll` *(Admin)*: Ghi danh sinh viên vào lớp học.

### 2.3 Quản lý Người dùng (`/api/users`) *(Admin)*
- `GET /api/users`: Danh sách tất cả tài khoản, lọc theo Role hoặc trạng thái kích hoạt.
- `PUT /api/users/{id}/toggle-status`: Khóa hoặc Mở khóa tài khoản người dùng (`IsActive = !IsActive`).

---

## 📱 3. NGHIỆP VỤ ĐIỂM DANH THÔNG MINH (`/api/attendance`)

### 3.1 Giảng viên tạo buổi điểm danh (`POST /api/attendance/sessions`)
- **Phân quyền:** `Teacher`, `Admin`
- **Request Body:**
```json
{
  "classRoomId": 1,
  "title": "Buổi 05: Điểm danh Dynamic QR & Radar GPS Geofencing",
  "startTime": "2026-10-21T13:00:00Z",
  "endTime": "2026-10-21T16:00:00Z",
  "qrRotateIntervalSeconds": 15,
  "requireGps": true,
  "requireBiometric": true
}
```

---

### 3.2 Lấy chi tiết buổi học & Dynamic QR Token xoay vòng (`GET /api/attendance/sessions/{id}`)
- **Mô tả:** Trả về thông tin buổi điểm danh. Nếu ca đang mở (`IsOpen = true`) và đã quá chu kỳ xoay (`QrRotateIntervalSeconds = 15s`), máy chủ tự động sinh mã Token QR mới.
- **Response 200 OK:**
```json
{
  "id": 1,
  "title": "Buổi 05: Điểm danh Dynamic QR & Radar GPS Geofencing",
  "currentQrToken": "eeac4631de8e486eaff91cebd7ba54ac",
  "qrRotateIntervalSeconds": 15,
  "latitude": 10.801832,
  "longitude": 106.714421,
  "allowedRadiusMeters": 50.0,
  "presentCount": 1,
  "lateCount": 0,
  "absentCount": 4
}
```

---

### 3.3 Sinh viên quét QR điểm danh (`POST /api/attendance/scan`)
- **Phân quyền:** `Student`
- **Cơ chế bảo mật:** Danh tính sinh viên được trích xuất trực tiếp từ Claims của JWT (`ClaimTypes.NameIdentifier`), tuyệt đối không tin cậy studentId do client tự gửi.
- **Request Body:**
```json
{
  "qrToken": "eeac4631de8e486eaff91cebd7ba54ac",
  "latitude": 10.801832,
  "longitude": 106.714421,
  "verificationMethod": "QR_GPS_FaceID",
  "deviceId": "Pixel_8_Pro_Hardware_ID_1669"
}
```
- **Kiểm tra nghiệp vụ Backend:**
  1. Token QR có khớp với ca điểm danh đang mở hay không (Nếu sai/quá hạn $\rightarrow$ ghi nhận cảnh báo `ExpiredQR`).
  2. Sinh viên có ghi danh trong lớp học hay không (Nếu không $\rightarrow$ ghi nhận cảnh báo `NotInClass`).
  3. Kiểm tra trùng điểm danh (`existingRecord`).
  4. Tính khoảng cách Geofencing Haversine giữa tọa độ sinh viên và phòng học. Nếu vượt quá `allowedRadiusMeters` (50m) $\rightarrow$ ghi nhận cảnh báo `LocationMismatch` và đánh dấu cần giảng viên duyệt.
- **Response 200 OK:**
```json
{
  "success": true,
  "message": "Điểm danh thành công! Trạng thái: Có mặt (Khoảng cách: 2.1m)",
  "status": "Present",
  "checkedInAt": "2026-10-21T13:42:00Z",
  "distanceMeters": 2.1
}
```

---

### 3.4 Giảng viên chỉnh sửa kết quả điểm danh (`PUT /api/attendance/records/{id}`)
- **Phân quyền:** `Teacher`, `Admin`
- **Mô tả:** Giảng viên điều chỉnh trạng thái (Có mặt / Trễ / Có phép / Vắng), bắt buộc lưu `EditReason` và đánh dấu `IsModifiedByTeacher = true` để lưu vết lịch sử kiểm toán.
- **Request Body:**
```json
{
  "status": "Excused",
  "reason": "Sinh viên có đơn xin phép sốt cao đã được phê duyệt"
}
```

---

## 🛡️ 4. SMART ATTENDANCE GUARD (`/api/attendance/alerts`)

- `GET /api/attendance/alerts`: Danh sách các cảnh báo điểm danh bất thường (quét QR hết hạn, ngoài vùng GPS, thiết bị bất thường, không thuộc lớp).
- `PUT /api/attendance/alerts/{id}/review`: Giảng viên xem xét và duyệt thủ công (Phê duyệt hoặc Từ chối).

---

## 📹 5. PHÒNG HỌP VIDEO NHÓM & THÔNG BÁO

- `POST /api/meetings`: Giảng viên tạo phòng họp WebRTC / Jitsi cho lớp học phần.
- `GET /api/meetings/{meetingCode}`: Lấy thông tin phòng họp (kiểm tra sinh viên có thuộc lớp trước khi cấp link kết nối).
- `GET /api/notifications`: Danh sách thông báo chuyên cần, cảnh báo cấm thi và lịch học.
