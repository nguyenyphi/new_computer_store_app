# 🛒 Ứng Dụng Bán Hàng Cửa Hàng Máy Tính (Computer Store)

Đồ án học phần **Lập trình thiết bị di động**  
Ứng dụng di động xây dựng bằng **Flutter (Dart, Material 3)**, nhắm nền tảng **Android**, kết nối Backend **ASP.NET Core Web API**.

> 📖 **Tài liệu vấn đáp bảo vệ đồ án:** Xem chi tiết tại [docs/GIAI_THICH.md](file:///Users/nguyenyphi/StudioProjects/new_computer_store_app/docs/GIAI_THICH.md) để nắm rõ luồng Đăng nhập, luồng Đặt hàng và Kiến trúc phân tầng 4 lớp.

---

## 📌 1. Cấu hình BASE_URL máy chủ Backend

Địa chỉ máy chủ API được cấu hình tập trung và hỗ trợ 3 cơ chế linh hoạt:
👉 `lib/core/config/app_config.dart`

### ⚡ Thứ tự ưu tiên xác định Server URL:
1. **Địa chỉ người dùng cấu hình trực tiếp trong App** (Lưu trong `SharedPreferences` - Ưu tiên cao nhất, đổi không cần build lại).
2. **Biến môi trường khi chạy:** `--dart-define=BASE_URL=...`
3. **Giá trị mặc định trong code:** `https://oldorangeapple30.conveyor.cloud/`

```dart
class AppConfig {
  /// Địa chỉ Backend mặc định (Conveyor Tunnel)
  static const String defaultBaseUrl = 'https://oldorangeapple30.conveyor.cloud/';
  ...
}
```

### 📱 Cách đổi địa chỉ máy chủ NGAY TRONG APP (Không cần build lại):
1. **Cách 1 (Từ màn hình Tài khoản):**
   - Vào tab **Tài khoản** -> tại mục **Cài đặt & Tùy chọn**, nhấn vào dòng **Cài đặt máy chủ (Server URL)**.
2. **Cách 2 (Từ màn hình Đăng nhập):**
   - **Nhấn giữ vào Logo hoặc Tiêu đề "Đăng Nhập"** (hoặc bấm vào icon Server ở góc trên bên phải màn hình).
3. **Các thao tác trong hộp thoại Cài Đặt Máy Chủ:**
   - **Nhập URL mới:** Ví dụ `https://new-subdomain.conveyor.cloud/` (app tự động kiểm tra và thêm `/` ở cuối).
   - **Nút "Kiểm tra kết nối":** Tự động gửi `GET {URL}/api/categories`, báo "Kết nối thành công" hoặc thông báo lỗi cụ thể bằng tiếng Việt.
   - **Nút "Lưu máy chủ":** Cập nhật Base URL của Dio ngay lập tức, lưu vào máy, xóa token cũ và đưa về màn Đăng nhập (hoàn toàn không cần tắt/mở lại app).
   - **Nút "Đặt lại mặc định":** Xóa cấu hình tùy chỉnh để quay về URL mặc định / dart-define.

> **Lưu ý bảo mật kết nối:**  
> Ứng dụng tuân thủ chuẩn HTTPS, bật kiểm tra chứng chỉ SSL hệ thống đầy đủ và tắt hoàn toàn cleartext HTTP.

---

## 🚀 2. Cách chạy ứng dụng

### Yêu cầu môi trường:
- Flutter SDK 3.13+ (hỗ trợ Material 3)
- Android Studio / VS Code / Antigravity IDE
- Thiết bị thật Android hoặc Android Emulator

### Các lệnh khởi chạy:

1. **Khởi chạy bình thường (Dùng URL mặc định Conveyor):**
   ```bash
   flutter run
   ```

2. **Khởi chạy với tham số `--dart-define` (Ghi đè URL máy chủ lúc chạy):**
   ```bash
   flutter run --dart-define=BASE_URL=https://oldorangeapple30.conveyor.cloud/
   ```
   *(Hoặc truyền bất kỳ địa chỉ Conveyor / Server nào khác khi backend khởi động lại)*

3. **Build file APK Debug:**
   ```bash
   flutter build apk --debug
   ```
   *File APK sau khi build nằm tại: `build/app/outputs/flutter-apk/app-debug.apk`*

---

## 📁 3. Cấu trúc thư mục mã nguồn (`lib/`)

```text
lib/
├── core/                           # Tầng hạ tầng dùng chung
│   ├── config/
│   │   ├── app_config.dart         # Cấu hình duy nhất BASE_URL và timeouts
│   │   └── app_router.dart         # Điều hướng GoRouter với ShellRoute và redirect logic
│   ├── network/
│   │   ├── api_client.dart         # Client Dio thực hiện HTTP GET/POST/PUT/DELETE
│   │   ├── api_exception.dart      # Xử lý & parse ProblemDetails RFC 7807 (tiếng Việt)
│   │   └── auth_interceptor.dart   # Tự động gắn Bearer Token và bắt lỗi 401 tự logout
│   ├── theme/
│   │   ├── app_colors.dart         # Bảng màu phong cách công nghệ (Cyan/Blue)
│   │   └── app_theme.dart          # Cấu hình Material 3 Light và Dark Theme
│   └── utils/
│       ├── currency_formatter.dart # Hàm định dạng tiền tệ "1.234.000 ₫"
│       └── validator.dart          # Kiểm tra tính hợp lệ dữ liệu form nhập liệu
│
├── data/                           # Tầng dữ liệu (Data Layer)
│   ├── models/                     # DTO & Entity models viết tay fromJson/toJson
│   │   ├── auth_response_model.dart# Model phản hồi xác thực token
│   │   ├── cart_item_model.dart    # Model dòng sản phẩm trong giỏ hàng (Local)
│   │   ├── category_model.dart     # Model danh mục sản phẩm
│   │   ├── create_order_request_model.dart # DTO gửi yêu cầu tạo đơn hàng
│   │   ├── order_model.dart        # Model danh sách & chi tiết đơn hàng
│   │   ├── paginated_response.dart # Model danh sách phân trang cuộn vô hạn
│   │   ├── payment_qr_model.dart   # Model dữ liệu thanh toán VietQR động
│   │   ├── product_color_model.dart# Model biến thể màu sắc sản phẩm
│   │   ├── product_model.dart      # Model chi tiết sản phẩm và tính toán giá
│   │   ├── spec_group_model.dart   # Model nhóm thông số kỹ thuật (ExpansionTile)
│   │   └── user_model.dart         # Model thông tin người dùng
│   ├── repositories/               # Cung cấp dữ liệu nghiệp vụ cho Providers
│   │   ├── auth_repository.dart    # Quản lý luồng đăng nhập, token, profile
│   │   ├── catalog_repository.dart # Quản lý danh mục, tìm kiếm và phân trang
│   │   └── order_repository.dart   # Quản lý tạo đơn, lấy đơn và VietQR
│   └── services/                   # Giao tiếp HTTP API & Bộ nhớ cục bộ
│       ├── auth_service.dart       # Gọi các endpoint /api/auth/* và /api/me
│       ├── auth_storage.dart       # Lưu trữ bảo mật Token qua flutter_secure_storage
│       ├── cart_storage.dart       # Lưu trữ giỏ hàng SharedPreferences (JSON)
│       ├── catalog_service.dart    # Gọi các endpoint /api/categories và /api/products
│       └── order_service.dart      # Gọi các endpoint /api/orders/*
│
├── providers/                      # Tầng quản lý trạng thái (ChangeNotifier)
│   ├── auth_provider.dart          # Trạng thái đăng nhập, đăng ký, OTP, logout
│   ├── cart_provider.dart          # Quản lý giỏ hàng local, đồng bộ giá & tồn kho
│   ├── catalog_provider.dart       # Trạng thái danh mục, tìm kiếm debounce 400ms, cuộn vô hạn
│   ├── order_provider.dart         # Tạo đơn, chặn bấm 2 lần, bắt lỗi 409, polling QR 10s
│   ├── product_detail_provider.dart# Trạng thái chọn màu sắc, số lượng, gallery ảnh
│   └── theme_provider.dart         # Chuyển đổi giao diện Sáng / Tối (Dark Mode)
│
├── ui/                             # Tầng giao diện người dùng (Presentation Layer)
│   ├── screens/
│   │   ├── account/
│   │   │   └── account_screen.dart # Màn hình Tài khoản (GET /api/me, Dark Mode, Logout)
│   │   ├── auth/
│   │   │   ├── forgot_password_screen.dart # Màn hình Quên mật khẩu
│   │   │   ├── login_screen.dart           # Màn hình Đăng nhập (hỗ trợ redirect sau login)
│   │   │   ├── otp_verification_screen.dart# Màn hình OTP (đếm ngược 60 giây gửi lại mã)
│   │   │   ├── register_screen.dart        # Màn hình Đăng ký tài khoản
│   │   │   └── reset_password_screen.dart  # Màn hình Đặt lại mật khẩu mới
│   │   ├── cart/
│   │   │   └── cart_screen.dart            # Màn hình Giỏ hàng (Tăng/giảm, cảnh báo đổi giá)
│   │   ├── catalog/
│   │   │   └── catalog_screen.dart         # Màn hình Danh mục & Lọc sản phẩm
│   │   ├── checkout/
│   │   │   └── checkout_screen.dart        # Màn hình Thanh toán (Form thông tin, QR/COD, Voucher)
│   │   ├── home/
│   │   │   └── home_screen.dart            # Màn hình Trang chủ (Search, Banner, Grid)
│   │   ├── orders/
│   │   │   ├── order_detail_screen.dart    # Màn hình Chi tiết đơn hàng (Sản phẩm, tổng tiền, trạng thái)
│   │   │   ├── order_success_screen.dart   # Màn hình Đặt hàng COD thành công
│   │   │   ├── orders_screen.dart          # Màn hình Danh sách đơn hàng (Pull-to-refresh, Chips)
│   │   │   └── payment_qr_screen.dart      # Màn hình VietQR (Polling 10s, Copy Clipboard)
│   │   ├── product_detail/
│   │   │   └── product_detail_screen.dart  # Chi tiết sản phẩm (Gallery, Màu sắc, Specs, Thêm vào giỏ)
│   │   ├── shell/
│   │   │   └── main_shell_screen.dart      # Bottom Navigation Bar 5 tab kèm Badge giỏ hàng
│   │   └── splash/
│   │       └── splash_screen.dart          # Màn hình Splash thương hiệu & kiểm tra xác thực
│   └── widgets/
│       ├── empty_view.dart         # Trạng thái danh sách rỗng
│       ├── error_view.dart         # Trạng thái lỗi mạng kèm nút Thử lại
│       ├── loading_view.dart       # Trạng thái đang tải dữ liệu
│       ├── product_card.dart       # Card sản phẩm (Cached image, nhãn giảm giá, hết hàng)
│       └── search_bar_widget.dart  # Ô tìm kiếm có nút xóa nhanh
│
└── main.dart                       # Điểm khởi động ứng dụng và khởi tạo MultiProvider
```

---

## 🛠️ 4. Tính năng đã hoàn thành theo yêu cầu

### Giai đoạn 1: Hạ tầng, Xác thực & Danh mục sản phẩm
1. **Hạ tầng & Mạng:**
   - Cấu hình duy nhất `BASE_URL` tại `app_config.dart`, hỗ trợ đổi qua `SharedPreferences` trong app và `--dart-define`.
   - `network_security_config.xml` tuân thủ bảo mật HTTPS chuẩn, bật kiểm tra chứng chỉ SSL hệ thống đầy đủ và tắt cleartext HTTP.
   - `ApiClient` với `Dio`, tự động gắn `Authorization: Bearer <token>`, bắt `401` tự động xóa token và chuyển về màn Đăng nhập.
   - Xử lý lỗi `ProblemDetails` theo chuẩn RFC 7807 với thông điệp tiếng Việt thân thiện.
   - Hỗ trợ đầy đủ **Dark Mode** và hàm định dạng tiền dùng chung **"1.234.000 ₫"**.
2. **Xác thực (Authentication):**
   - Đăng nhập, Đăng ký, Quên mật khẩu, Đặt lại mật khẩu.
   - Nhận diện mã lỗi `EMAIL_NOT_VERIFIED` từ server để tự chuyển sang màn hình OTP.
   - Màn hình OTP với **bộ đếm ngược 60 giây** cho nút "Gửi lại mã".
   - Màn hình Tài khoản gọi `GET /api/me`, chuyển đổi Dark Mode và Đăng xuất an toàn.
3. **Catalog & Sản phẩm:**
   - Danh mục sản phẩm (`GET /api/categories`).
   - Lưới sản phẩm phân trang cuộn vô hạn (`GET /api/products?categoryId=&q=&page=&pageSize=`).
   - Ô tìm kiếm với kỹ thuật **Debounce 400ms**.
   - Chi tiết sản phẩm: Gallery ảnh vuốt ngang (`PageView`), chọn biến thể màu sắc, mô tả, bảng thông số theo nhóm (`ExpansionTile`), chọn số lượng không vượt tồn kho.

### Giai đoạn 2: Giỏ hàng, Checkout, VietQR & Quản lý đơn hàng
1. **A. Giỏ hàng Cục bộ (Local Cart):**
   - Lưu trữ bền vững bằng `shared_preferences` dưới định dạng JSON (`CartStorage`).
   - Mỗi item gồm: `productId`, `colorId`, tên, ảnh, giá hiển thị, số lượng.
   - Nút "Thêm vào giỏ" ở trang chi tiết sản phẩm hoạt động thật sự: tự động cộng dồn số lượng nếu trùng cả `productId` và `colorId`.
   - **Tự động làm mới dữ liệu từ server:** Khi mở Giỏ hàng hoặc vào màn Checkout, app gọi `GET /api/products/{id}` để cập nhật giá mới nhất và số lượng tồn kho thực tế.
   - Cảnh báo trực quan *"Một số sản phẩm đã thay đổi giá hoặc hết hàng"* nếu phát hiện giá khác so với lần lưu trước.
   - Hỗ trợ tăng/giảm số lượng, chặn không cho tăng vượt tồn kho, xóa sản phẩm, tính tổng tạm tính theo thời gian thực.
   - **Badge số lượng** hiển thị trực tiếp trên tab Giỏ hàng của thanh điều hướng dưới.
   - **Giữ nguyên giỏ hàng khi người dùng Đăng xuất** (dữ liệu giỏ gắn với thiết bị).
2. **B. Checkout (Thanh toán đơn hàng):**
   - Bắt buộc đăng nhập: Nếu khách chưa đăng nhập, tự động chuyển sang màn Đăng nhập kèm tham số `from=/checkout` để sau khi đăng nhập thành công sẽ quay lại ngay màn Checkout.
   - Tự động điền trước thông tin Họ tên, Email, SĐT từ `GET /api/me`.
   - Form nhập: Họ tên, Số điện thoại (kiểm tra regex định dạng Việt Nam), Địa chỉ giao hàng chi tiết, Mã voucher (tùy chọn).
   - Chọn Phương thức thanh toán: `QR` (Chuyển khoản VietQR) hoặc `COD` (Thanh toán khi nhận hàng).
   - Gọi `POST /api/orders` với cấu trúc `items[{productId, colorId, quantity}]`.
   - **Chống click đúp:** Disable nút "Xác nhận đặt hàng" và hiện loading spinner khi đang gửi yêu cầu.
   - **Bắt lỗi 409 CONCURRENCY_CONFLICT:** Hiển thị thông báo *"Sản phẩm vừa thay đổi hoặc hết hàng, vui lòng kiểm tra lại giỏ hàng"* và tự động làm mới lại giỏ hàng.
   - Hiển thị chính xác các thông điệp validation/tồn kho do backend trả về.
   - Sau khi tạo đơn thành công: Tự động xóa giỏ hàng local và chuyển hướng sang màn hình tương ứng (`/orders/{id}/payment-qr` nếu chọn QR hoặc `/order-success/{id}` nếu chọn COD).
3. **C. Màn hình Thanh toán VietQR:**
   - Gọi `GET /api/orders/{id}/payment-qr` lấy thông tin mã VietQR động theo đơn hàng.
   - Hiển thị ảnh QR VietQR, Tổng số tiền cần thanh toán, Tên ngân hàng, Số tài khoản, Tên chủ tài khoản, và Nội dung chuyển khoản.
   - Nút sao chép tiện lợi (sao chép số tài khoản & nội dung chuyển khoản vào Clipboard) kèm thông báo SnackBar.
   - **Tự động làm mới trạng thái (Polling):** Dùng `Timer.periodic` gọi `GET /api/orders/{id}` mỗi 10 giây để kiểm tra trạng thái đơn.
   - Khi trạng thái chuyển từ `Pending` sang đã thanh toán hoặc khi người dùng rời màn hình, timer tự động bị hủy (`dispose`) để tránh rò rỉ tài nguyên. Khi thanh toán hoàn tất, tự động chuyển về trang chi tiết đơn.
4. **D. Quản lý Đơn hàng (Orders):**
   - Danh sách đơn hàng (`GET /api/orders`) sắp xếp mới nhất lên đầu, hỗ trợ **Pull-to-Refresh**.
   - Hiển thị Chip màu theo trạng thái: Chờ xử lý (`Pending` - Cam), Đang xử lý (`Processing` - Xanh dương), Đang giao (`Shipped` - Tím), Đã giao (`Delivered` - Xanh lá), Đã hủy (`Cancelled` - Đỏ).
   - Chi tiết đơn hàng (`GET /api/orders/{id}`): Hiển thị đầy đủ danh sách sản phẩm đã mua, ảnh đại diện, màu sắc, đơn giá, số lượng, tạm tính, voucher giảm giá, tổng tiền thanh toán, thông tin người nhận và thời gian tạo đơn.
   - Có nút **"Xem QR thanh toán"** nổi bật nếu đơn hàng chưa thanh toán và chọn phương thức QR.

---

## 🎬 5. Kịch bản Demo từng bước (Step-by-Step Demo Script)

Chuẩn bị: Đảm bảo Backend ASP.NET Core đang chạy qua Conveyor (`https://oldorangeapple30.conveyor.cloud/`) hoặc đã được cấu hình trong app và ứng dụng Flutter đã được cài lên máy Android.

### Bước 1: Khởi chạy và Xem sản phẩm
1. Mở ứng dụng `New Computer Store`. Ứng dụng sẽ mở vào **Trang chủ**.
2. Cuộn xem banner khuyến mãi và danh sách "Sản phẩm nổi bật".
3. Nhấp vào ô tìm kiếm, gõ thử từ khóa (ví dụ: `Laptop`, `Asus`), ứng dụng tự động debounce 400ms và hiển thị kết quả.
4. Chuyển sang tab **Danh mục**, chọn một danh mục (ví dụ: Laptop Gaming) để xem lưới lọc sản phẩm.

### Bước 2: Xem chi tiết và Thêm vào giỏ hàng
1. Bấm vào một sản phẩm còn hàng để mở màn hình **Chi tiết sản phẩm**.
2. Vuốt ngang bộ sưu tập ảnh (Gallery `PageView`).
3. Bấm chọn các nút biến thể màu sắc (ví dụ: Đen, Xám) và quan sát hình ảnh/màu sắc tương ứng.
4. Bấm mở rộng phần "Thông số kỹ thuật" (`ExpansionTile`).
5. Dùng nút `+` để chọn số lượng (thử tăng vượt số lượng tồn kho xem nút có bị vô hiệu hóa không).
6. Bấm nút **"Thêm vào giỏ hàng"**: SnackBar thông báo *"Đã thêm vào giỏ hàng thành công!"* sẽ xuất hiện.
7. Nhìn xuống thanh Navigation: tab **Giỏ hàng** lập tức xuất hiện **Badge màu đỏ** hiển thị số lượng sản phẩm.
8. Bấm thêm một lần nữa với cùng màu sắc: số lượng trong giỏ sẽ được tự động cộng dồn.

### Bước 3: Xem giỏ hàng và Kiểm tra làm mới giá/tồn kho
1. Nhấp vào tab **Giỏ hàng**.
2. Ứng dụng tự động kích hoạt đồng bộ `GET /api/products/{id}` trong nền để đối chiếu giá và số lượng tồn thực tế.
3. Thử bấm nút `+` hoặc `-` để thay đổi số lượng, hoặc bấm icon Thùng rác để xóa sản phẩm.
4. Tổng tiền tạm tính ở thanh dưới cùng tự động cập nhật mượt mà.

### Bước 4: Đăng nhập và Đặt hàng (Checkout)
1. Bấm nút **"Tiến hành đặt hàng"**.
2. Nếu chưa đăng nhập: Ứng dụng tự động điều hướng sang màn hình **Đăng nhập**, kèm thông báo *"Vui lòng đăng nhập để tiến hành thanh toán"*.
3. Nhập tài khoản và mật khẩu $\rightarrow$ Bấm **Đăng nhập**. Ngay sau khi đăng nhập thành công, app sẽ tự động chuyển thẳng về màn hình **Thanh toán (Checkout)** mà không bị mất giỏ hàng.
4. Trên màn hình Checkout:
   - Các trường Họ tên, Email, Số điện thoại được tự động điền sẵn từ profile người dùng.
   - Nhập Địa chỉ nhận hàng (ví dụ: `123 Đường Nguyễn Văn Cừ, Quận 5, TP.HCM`).
   - Thử nhập sai định dạng Số điện thoại (ví dụ: ít hơn 10 chữ số) để thấy thông báo lỗi validation tiếng Việt.
   - Nhập mã giảm giá Voucher nếu có.
   - Chọn phương thức thanh toán: Chọn **"Chuyển khoản mã VietQR"**.
5. Bấm nút **"Xác nhận đặt hàng"**: Nút chuyển sang trạng thái loading xoay tròn, ngăn chặn người dùng bấm đúp gửi nhiều đơn.

### Bước 5: Màn hình Thanh toán VietQR & Tự động Polling
1. Ứng dụng điều hướng sang màn hình **Mã QR Thanh Toán**:
   - Ảnh mã QR chuẩn VietQR được hiển thị rõ ràng ở trung tâm.
   - Hiển thị đầy đủ Ngân hàng, Số tài khoản, Chủ tài khoản, Số tiền và Nội dung chuyển khoản.
2. Bấm nút icon **Sao chép** bên cạnh Số tài khoản hoặc Nội dung: SnackBar thông báo *"Đã sao chép vào bộ nhớ tạm"*.
3. Màn hình tự động kích hoạt bộ đếm thời gian `Timer.periodic` mỗi 10 giây gọi API để kiểm tra trạng thái đơn.
4. Khi Admin trên Backend hoặc hệ thống ngân hàng cập nhật trạng thái đơn thành công $\rightarrow$ màn hình tự động phát hiện và chuyển sang thông báo hoàn tất.

### Bước 6: Quản lý và Xem lại Đơn hàng
1. Nhấp sang tab **Đơn hàng** trên thanh điều hướng.
2. Danh sách tất cả đơn hàng đã đặt xuất hiện với đơn mới nhất ở trên cùng.
3. Kéo xuống để thực hiện **Pull-to-Refresh**.
4. Quan sát các Chip màu trạng thái: Đơn vừa đặt hiển thị chip màu cam **"Chờ xử lý"**.
5. Bấm vào đơn hàng để mở **Chi tiết đơn hàng**:
   - Xem lại danh sách các mặt hàng, hình ảnh, màu sắc, số lượng, giá mua.
   - Kiểm tra tổng tiền, phí, voucher và địa chỉ giao hàng.
   - Với đơn hàng chưa thanh toán, nút **"Xem QR thanh toán"** màu xanh xuất hiện ở góc dưới để người dùng có thể quét lại mã QR bất cứ lúc nào.

### Bước 7: Kiểm tra Giữ nguyên giỏ hàng khi Đăng xuất
1. Vào tab **Tài khoản** $\rightarrow$ Bấm **Đăng xuất**.
2. Chuyển lại tab **Giỏ hàng**: Toàn bộ sản phẩm đã thêm trước đó vẫn còn nguyên vẹn trong bộ nhớ máy (theo đúng yêu cầu đề bài).

---

## 🧪 6. Danh sách các trường hợp kiểm thử lỗi (Edge Cases & Fault Testing)

Để kiểm tra độ bền và khả năng chịu lỗi của ứng dụng trong thực tế, vui lòng thực hiện các bài test sau:

### 1. Kiểm thử Mất kết nối mạng (Network Connection Lost / Server Offline)
- **Cách thử:**
  1. Tắt Wi-Fi trên điện thoại Android hoặc tạm tắt dịch vụ Backend ASP.NET Core trên máy chủ.
  2. Tại app, chuyển giữa các màn hình Trang chủ, Danh mục, Đơn hàng hoặc bấm "Đặt hàng".
- **Kết quả kỳ vọng:**
  - Ứng dụng không bị crash màn hình đỏ (`RenderFlex overflow` hay unhandled exception).
  - Xuất hiện giao diện `ErrorView` với icon mất mạng và thông báo tiếng Việt: *"Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng hoặc liên hệ quản trị viên."*
  - Xuất hiện nút bấm **"Thử lại"**.
  - Bật lại Wi-Fi hoặc mở lại backend $\rightarrow$ bấm "Thử lại", dữ liệu tải lại bình thường.

### 2. Kiểm thử Hết hàng / Xung đột tồn kho đồng thời (Concurrency Conflict 409)
- **Cách thử:**
  1. Thêm 1 sản phẩm có số lượng tồn kho còn ít (ví dụ: còn 1 cái) vào giỏ hàng trên điện thoại.
  2. Mở trình duyệt web hoặc công cụ Swagger/Postman, dùng tài khoản khác đặt mua hết số lượng sản phẩm đó, hoặc sửa trực tiếp trong Database để `StockQuantity = 0`.
  3. Quay lại điện thoại và bấm **"Xác nhận đặt hàng"** trên màn hình Checkout.
- **Kết quả kỳ vọng:**
  - Backend ASP.NET Core phát hiện `RowVersion` Concurrency Token bị thay đổi và trả mã lỗi `HTTP 409 Conflict` (`CONCURRENCY_CONFLICT`).
  - Ứng dụng bắt đúng mã lỗi 409 và hiển thị SnackBar thông báo:  
    👉 *"Sản phẩm vừa thay đổi hoặc hết hàng, vui lòng kiểm tra lại giỏ hàng"*
  - Nút đặt hàng không bị treo hay gửi lặp đơn.
  - Người dùng quay lại giỏ hàng sẽ thấy thông báo cập nhật tình trạng tồn kho mới nhất.

### 3. Kiểm thử Token hết hạn hoặc không hợp lệ (Unauthorized 401 Auto-Logout)
- **Cách thử:**
  1. Đăng nhập vào app để nhận JWT Token.
  2. Dùng công cụ quản lý cơ sở dữ liệu xóa người dùng đó, hoặc xóa/chỉnh sửa token trong bộ nhớ bằng cách xóa Keystore, hoặc đợi token JWT hết hạn (exp expired).
  3. Từ app, thực hiện một thao tác cần quyền xác thực (ví dụ: vào tab Đơn hàng, hoặc bấm Đặt hàng).
- **Kết quả kỳ vọng:**
  - `AuthInterceptor` của `ApiClient` bắt mã lỗi `401 Unauthorized`.
  - Hệ thống tự động xóa sạch token hết hạn trong `AuthStorage`.
  - Hiển thị SnackBar thông báo: *"Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."*
  - Ứng dụng tự động điều hướng người dùng về màn hình **Đăng nhập** một cách an toàn.

### 4. Kiểm thử Chặn bấm đặt hàng 2 lần (Double-click Prevention)
- **Cách thử:**
  - Tại màn hình Checkout, bấm thật nhanh liên tiếp nhiều lần vào nút **"Xác nhận đặt hàng"**.
- **Kết quả kỳ vọng:**
  - Ngay từ lần chạm đầu tiên, cờ `_isSubmitting = true` được kích hoạt.
  - Nút bấm lập tức bị vô hiệu hóa (`onPressed: null`) và hiển thị biểu tượng quay vòng chờ xử lý.
  - Chỉ có duy nhất **1 đơn hàng** được tạo trên backend, hoàn toàn không bị trùng lặp đơn.
