-- ==============================================================
-- KỊCH BẢN TẠO DỮ LIỆU MẪU (SEED DATA) CHO CỬA HÀNG MÁY TÍNH
-- Hệ cơ sở dữ liệu: SQL Server (T-SQL) / Entity Framework Core
-- ==============================================================

-- 1. DANH MỤC SẢN PHẨM (Categories)
SET IDENTITY_INSERT Categories ON;

INSERT INTO Categories (CategoryId, CategoryName, ImageUrl) VALUES
(1, N'Laptop', 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=600'),
(2, N'PC & Máy trạm', 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=600'),
(3, N'Linh kiện máy tính', 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600'),
(4, N'Màn hình máy tính', 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=600'),
(5, N'Bàn phím & Chuột', 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600');

SET IDENTITY_INSERT Categories OFF;

-- 2. SẢN PHẨM (Products)
SET IDENTITY_INSERT Products ON;

INSERT INTO Products (ProductId, CategoryId, ProductName, Price, DiscountPercent, StockQuantity, ImageUrl, Description) VALUES
(1, 1, N'Laptop Gaming ASUS ROG Zephyrus G16 (2024)', 54990000, 10, 15, 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800', N'ASUS ROG Zephyrus G16 là chiến thần gaming mỏng nhẹ với vi xử lý Intel Core Ultra 9, RTX 4080 và màn hình ROG Nebula OLED 240Hz 2.5K.'),
(2, 1, N'Apple MacBook Pro 16 inch M3 Max (36GB / 1TB SSD)', 89990000, 5, 10, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800', N'MacBook Pro 16 inch M3 Max mang đến hiệu năng tột bậc cho chuyên gia với 14 nhân CPU, 30 nhân GPU, màn hình Liquid Retina XDR và pin 22 giờ.'),
(3, 1, N'Laptop Gaming Lenovo Legion Pro 7i Gen 9 (RTX 4090)', 76990000, 12, 8, 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800', N'Lenovo Legion Pro 7i trang bị vi xử lý i9-14900HX, RTX 4090 16GB VRAM, tản nhiệt buồng hơi Legion ColdFront tân tiến.'),
(4, 1, N'Laptop Doanh Nhân Dell XPS 15 9530 OLED Touch', 48990000, 8, 0, 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800', N'Thiết kế sợi carbon sang trọng, màn hình InfinityEdge 3.5K OLED cảm ứng và âm thanh Waves Nx 3D.'),
(5, 2, N'PC Gaming ROG Strix G16CH (i7 14700F / RTX 4070 Super)', 42990000, 15, 12, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=800', N'Dàn PC Gaming đồng bộ ROG Strix với tản nhiệt nước AIO, hiệu năng bùng nổ từ RTX 4070 Super phục vụ mọi tựa game AAA.'),
(6, 2, N'Máy Trạm Workstation Dell Precision 3660 Tower', 52000000, 0, 6, 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=800', N'Máy trạm chuyên nghiệp phục vụ mô phỏng AI, dựng hình kiến trúc CAD/CAM và biên tập phim chuyên dụng.'),
(7, 3, N'Card Màn Hình ASUS ROG Strix GeForce RTX 4090 OC 24GB', 59990000, 7, 5, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=800', N'Đỉnh cao đồ họa với vi kiến trúc Ada Lovelace, 24GB VRAM GDDR6X, quạt công nghệ hướng trục Axial-tech.'),
(8, 3, N'Bộ Vi Xử Lý CPU Intel Core i9-14900K Box Chính Hãng', 15490000, 5, 25, 'https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=800', N'CPU Intel Core i9 thế hệ 14 Raptor Lake Refresh với xung nhịp turbo đạt tới 6.0GHz ngay khi xuất xưởng.'),
(9, 4, N'Màn Hình Gaming OLED LG UltraGear 27GR95QE-B (27" 240Hz 0.03ms)', 21990000, 18, 14, 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800', N'Màn hình OLED gaming 27 inch 240Hz, phản hồi siêu tốc 0.03ms GtG, tương phản vô hạn với màu đen tuyệt đối.'),
(10, 5, N'Bàn Phím Cơ Không Dây ASUS ROG Azoth 75% OLED RGB', 6490000, 10, 20, 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800', N'Bàn phím cơ Custom layout 75%, màn hình OLED 2 inch, đệm silicone giảm chấn 3 lớp êm ái, switch ROG NX lube sẵn.'),
(11, 5, N'Chuột Gaming Siêu Nhẹ Logitech G Pro X Superlight 2 (60g)', 3690000, 8, 30, 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=800', N'Huyền thoại Esports phiên bản 2 với cảm biến HERO 2 32.000 DPI, switch lai quang cơ LIGHTFORCE.');

SET IDENTITY_INSERT Products OFF;

-- 3. MÀU SẮC BIẾN THỂ (ProductColors)
SET IDENTITY_INSERT ProductColors ON;

INSERT INTO ProductColors (Id, ProductId, ColorName, ColorHex) VALUES
(1, 1, N'Xám Không Gian (Eclipse Gray)', '#2D3142'),
(2, 1, N'Trắng Bạch Kim (Platinum White)', '#EAEAEA'),
(3, 2, N'Đen Không Gian (Space Black)', '#1E1E24'),
(4, 2, N'Bạc Cổ Điển (Silver)', '#D8D8D8'),
(5, 3, N'Xám Onyx (Onyx Grey)', '#333533'),
(6, 4, N'Bạc / Đen Carbon', '#202020'),
(7, 5, N'Đen ROG Cyber (Aura RGB)', '#121212'),
(8, 6, N'Đen Nhám Doanh Nghiệp', '#1F1F1F'),
(9, 7, N'Đen Xám Kim Loại', '#1C1D21'),
(10, 8, N'Xanh Intel Box', '#0071C5'),
(11, 9, N'Đen Nhám Gaming', '#181818'),
(12, 10, N'Xám Đen Không Gian', '#252627'),
(13, 10, N'Trắng Tuyết (Moonlight White)', '#F0F0F0'),
(14, 11, N'Đen Nhám (Black)', '#111111'),
(15, 11, N'Trắng Ngọc (White)', '#F5F5F5'),
(16, 11, N'Hồng Magenta', '#E20074');

SET IDENTITY_INSERT ProductColors OFF;

-- 4. BỘ SƯU TẬP ẢNH SẢN PHẨM (ProductImages)
INSERT INTO ProductImages (ProductId, ImageUrl) VALUES
(1, 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800'),
(1, 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800'),
(1, 'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=800'),
(2, 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800'),
(2, 'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=800');

-- 5. THÔNG SỐ KỸ THUẬT (SpecGroups & Specs)
SET IDENTITY_INSERT SpecGroups ON;
INSERT INTO SpecGroups (SpecGroupId, ProductId, GroupName) VALUES
(1, 1, N'Hiệu năng & Cấu hình'),
(2, 1, N'Màn hình & Hiển thị'),
(3, 2, N'Cấu hình xử lý');
SET IDENTITY_INSERT SpecGroups OFF;

INSERT INTO Specs (SpecGroupId, SpecName, SpecValue) VALUES
(1, N'CPU', N'Intel Core Ultra 9 185H (16 Nhân 22 Luồng, Up to 5.1GHz)'),
(1, N'RAM', N'32GB LPDDR5X 7467MHz Onboard'),
(1, N'VGA', N'NVIDIA GeForce RTX 4080 12GB GDDR6 (115W TGP)'),
(1, N'Ổ cứng', N'1TB M.2 NVMe PCIe 4.0 SSD'),
(2, N'Kích thước', N'16.0 inch 16:10 2.5K (2560 x 1600) ROG Nebula OLED 240Hz'),
(3, N'Chip', N'Apple M3 Max (14 nhân CPU, 30 nhân GPU)'),
(3, N'RAM', N'36GB Unified Memory');
