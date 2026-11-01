# 📚 Tài Liệu Hướng Dẫn Vấn Đáp & Giải Thích Kiến Trúc

Tài liệu tóm tắt súc tích các luồng nghiệp vụ cốt lõi và kiến trúc ứng dụng (từ 5 - 8 dòng mỗi phần), giúp sinh viên tự tin giải trình và trả lời xuất sắc câu hỏi của giảng viên trong buổi bảo vệ đồ án môn **Lập trình thiết bị di động**.

---

## 🔐 1. Luồng Đăng Nhập & Xác Thực (Authentication Flow)
1. **Khởi tạo & Kiểm tra Token:** Khi mở app, màn hình `SplashScreen` gọi `AuthProvider.checkInitialAuth()` đọc JWT token từ `flutter_secure_storage` (Android Keystore); nếu token còn hạn, app gọi `GET /api/me` lấy thông tin và vào thẳng Trang chủ, ngược lại giữ trạng thái khách vãng lai.
2. **Gửi thông tin xác thực:** Người dùng nhập Email, Mật khẩu $\rightarrow$ `AuthService` gửi `POST /api/auth/login`. Nếu thành công, token được lưu an toàn vào Keystore và `AuthProvider` cập nhật trạng thái `isAuthenticated = true`.
3. **Xử lý tài khoản chưa kích hoạt OTP:** Nếu máy chủ trả về mã lỗi `EMAIL_NOT_VERIFIED`, ứng dụng tự động điều hướng sang màn hình OTP (`/otp-verify`) kèm bộ đếm ngược 60 giây để gửi lại mã xác thực qua `POST /api/auth/verify-email`.
4. **Tự động gắn Token & Bắt lỗi 401:** Mọi request tiếp theo đều được `AuthInterceptor` (Dio) tự động đính kèm header `Authorization: Bearer <token>`.
5. **Cơ chế Auto-Logout an toàn:** Khi token hết hạn hoặc máy chủ trả `401 Unauthorized`, `AuthInterceptor` kích hoạt callback xóa sạch token trong Keystore, hiển thị thông báo phiên hết hạn và tự động đưa người dùng về màn Đăng nhập.

---

## 🛒 2. Luồng Đặt Hàng & Thanh Toán VietQR (Order & Checkout Flow)
1. **Giỏ hàng Cục bộ (Local Cart):** Sản phẩm được lưu trong `shared_preferences` dưới dạng JSON (`productId`, `colorId`, `quantity`, đơn giá hiển thị); dữ liệu giỏ gắn liền thiết bị và được giữ nguyên khi người dùng đăng xuất.
2. **Làm mới giá & Tồn kho thực tế:** Khi mở Giỏ hàng hoặc vào Checkout, app tự động gọi `GET /api/products/{id}` đối chiếu giá mới nhất và tồn kho từ server, tự động cảnh báo nếu giá thay đổi và chặn không cho tăng vượt tồn kho.
3. **Bắt buộc Đăng nhập tại Checkout:** Khách vãng lai bấm đặt hàng sẽ được chuyển sang màn Đăng nhập với tham số `from=/checkout`, đăng nhập xong tự động điều hướng quay lại Checkout mà không mất thông tin giỏ.
4. **Gửi đơn hàng & Chống Spam:** Người dùng chọn phương thức ("QR" hoặc "COD"), nhập địa chỉ và bấm đặt hàng; nút bấm lập tức bị vô hiệu hóa để chống click đúp, gửi `POST /api/orders` với danh sách `items[{productId, colorId, quantity}]`.
5. **Xử lý Xung đột 409 & VietQR Polling 10s:** Nếu server báo `409 CONCURRENCY_CONFLICT` (xung đột tồn kho do người khác mua trước), app thông báo người dùng kiểm tra lại giỏ; nếu thành công, giỏ hàng local được xóa sạch, app mở màn hình VietQR (`GET /api/orders/{id}/payment-qr`) và chạy `Timer.periodic` mỗi 10 giây thăm dò trạng thái đơn đến khi thanh toán xong.

---

## 📁 3. Cấu Trúc Thư Mục & Phân Tầng Kiến Trúc (`lib/`)
1. **Mô hình kiến trúc phân tầng chuẩn:** Dự án phân chia nghiêm ngặt thành 4 tầng: `core` (hạ tầng, mạng, theme, config), `data` (models, services, repositories), `providers` (quản trị trạng thái) và `ui` (màn hình, widgets).
2. **Tầng Core:** Quản lý cấu hình tập trung duy nhất `BASE_URL` tại `app_config.dart`, bộ định tuyến điều hướng `GoRouter` tại `app_router.dart`, và client mạng `ApiClient` (Dio) bắt lỗi theo chuẩn RFC 7807 `ProblemDetails`.
3. **Tầng Data:** Các DTO models được viết tay thuần túy `fromJson`/`toJson` (không phụ thuộc thư viện sinh mã `build_runner`), `Services` chịu trách nhiệm gọi HTTP RESTful API, và `Repositories` đóng gói logic dữ liệu cung cấp cho UI.
4. **Tầng Providers:** Sử dụng State Management `Provider` (`ChangeNotifier`) tách biệt hoàn toàn logic nghiệp vụ khỏi giao diện, gồm `AuthProvider`, `CartProvider`, `CatalogProvider`, `OrderProvider`, `ThemeProvider`.
5. **Tầng UI:** Áp dụng Material 3 với giao diện công nghệ Light/Dark Theme, thiết kế module hóa màn hình và tái sử dụng triệt để các widget dùng chung (`LoadingView`, `ErrorView`, `EmptyView`, `ProductCard`, `SearchBarWidget`).

---

## 🤖 4. Trợ Lý AI Chatbot Tư Vấn Công Nghệ (AI Assistant Feature)
1. **Kiến trúc Chatbot Provider:** Quản lý hội thoại thông qua `ChatbotProvider`, lưu giữ danh sách tin nhắn `ChatMessageModel`, trạng thái đang soạn `isTyping` và hỗ trợ xóa lịch sử chat.
2. **Bộ máy phân tích ý định (Intent Recognition):** Phân tích câu hỏi tự nhiên của khách hàng về Laptop Gaming, Laptop Văn phòng, Build PC, CPU, Card đồ họa RTX, Màn hình, Bàn phím cơ hoặc Chính sách bảo hành.
3. **Nhúng sản phẩm trực tiếp (Embedded Product Cards):** Khi tư vấn dòng máy phù hợp, Chatbot tự động đính kèm các Card sản phẩm thu nhỏ (ảnh, giá, tên) kèm nút "Xem chi tiết" điều hướng trực tiếp sang `/product/:id`.
4. **Trải nghiệm hội thoại tự nhiên:** Mô phỏng độ trễ suy nghĩ của AI (650ms) kèm hiệu ứng ba chấm nhấp nháy (typing indicator) và hệ thống gợi ý câu hỏi nhanh (Quick Reply Chips) giúp thao tác nhanh chóng bằng 1 chạm.
5. **Tích hợp toàn diện:** Người dùng có thể gọi Trợ lý AI bất kỳ lúc nào thông qua nút Floating Action Button ở Trang chủ hoặc từ mục Hỗ trợ trong màn hình Tài khoản.

---

## 🌐 5. Cơ Chế Cấu Hình & Đổi Địa Chỉ Máy Chủ Động (Dynamic Server URL)
1. **Thứ tự ưu tiên 3 cấp:** Khi xác định Base URL, app ưu tiên: (1) Địa chỉ tùy chỉnh người dùng lưu trong `SharedPreferences` $\rightarrow$ (2) Biến môi trường lúc chạy `--dart-define=BASE_URL=...` $\rightarrow$ (3) Địa chỉ mặc định trong mã nguồn (`defaultBaseUrl`).
2. **Đổi máy chủ không cần khởi động lại:** Khi người dùng đổi địa chỉ trong app, `ApiClient.updateBaseUrl()` thay đổi trực tiếp `_dio.options.baseUrl`, giúp toàn bộ các lệnh gọi API sau đó kết nối ngay đến máy chủ mới mà không cần restart app.
3. **Bảo mật phiên đăng nhập:** Khi lưu máy chủ mới, ứng dụng tự động xóa sạch JWT Token trong Keystore (`authProvider.logout()`) và chuyển về màn Đăng nhập để tránh rò rỉ hoặc sai lệch phiên giữa các backend khác nhau.
4. **Kiểm tra kết nối trực tiếp:** Trước khi lưu, người dùng có thể bấm "Kiểm tra kết nối" để app gửi `GET /api/categories` thăm dò trạng thái hoạt động của máy chủ và hiển thị kết quả bằng tiếng Việt rõ ràng.
5. **Tiện ích mở nhanh:** Mở qua tab Tài khoản -> "Cài đặt máy chủ (Server URL)" hoặc mở trực tiếp trên màn hình Đăng nhập bằng cách nhấn giữ vào Logo / Tiêu đề.

