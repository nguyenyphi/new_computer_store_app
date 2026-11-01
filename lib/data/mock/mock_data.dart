import '../models/category_model.dart';
import '../models/paginated_response.dart';
import '../models/product_color_model.dart';
import '../models/product_model.dart';
import '../models/spec_group_model.dart';

/// Dữ liệu mẫu chuẩn bị sẵn (Mock Data)
/// Dùng làm dữ liệu dự phòng khi máy chủ backend ASP.NET Core trong mạng LAN chưa kết nối được,
/// giúp giao diện ứng dụng luôn hiển thị đầy đủ danh mục và sản phẩm phong phú để sinh viên demo.
class MockData {
  MockData._();

  /// 1. Danh sách Danh mục sản phẩm
  static final List<CategoryModel> categories = [
    CategoryModel(
      categoryId: 1,
      categoryName: 'Laptop',
      productCount: 4,
      imageUrl: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=600',
    ),
    CategoryModel(
      categoryId: 2,
      categoryName: 'PC & Máy trạm',
      productCount: 2,
      imageUrl: 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=600',
    ),
    CategoryModel(
      categoryId: 3,
      categoryName: 'Linh kiện máy tính',
      productCount: 3,
      imageUrl: 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600',
    ),
    CategoryModel(
      categoryId: 4,
      categoryName: 'Màn hình máy tính',
      productCount: 2,
      imageUrl: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=600',
    ),
    CategoryModel(
      categoryId: 5,
      categoryName: 'Bàn phím & Chuột',
      productCount: 2,
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=600',
    ),
  ];

  /// 2. Danh sách Sản phẩm chi tiết
  static final List<ProductModel> products = [
    // --- LAPTOP ---
    ProductModel(
      productId: 1,
      productName: 'Laptop Gaming ASUS ROG Zephyrus G16 (2024)',
      price: 54990000,
      discountPercent: 10,
      finalPrice: 49491000,
      quantity: 12,
      imageUrl: 'https://images.unsplash.com/photo-1593642632823-8f785ba67e45?w=800',
      categoryId: 1,
      categoryName: 'Laptop',
      description:
          'ASUS ROG Zephyrus G16 (2024) là chiến thần gaming mỏng nhẹ đỉnh cao với khung nhôm CNC nguyên khối, trang bị chip Intel Core Ultra 9 tích hợp NPU AI, card đồ họa RTX 4080 và màn hình ROG Nebula OLED 2.5K 240Hz chuẩn màu 100% DCI-P3.',
      additionalImages: [
        'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800',
        'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=800',
      ],
      productColors: [
        ProductColorModel(id: 1, productId: 1, colorName: 'Xám Không Gian (Eclipse Gray)', colorCode: '#2D3142', quantity: 6),
        ProductColorModel(id: 2, productId: 1, colorName: 'Trắng Bạch Kim (Platinum White)', colorCode: '#EAEAEA', quantity: 6),
      ],
      specGroups: [
        SpecGroupModel(
          id: 1,
          name: 'Hiệu năng & Cấu hình',
          specKeys: [
            SpecKeyModel(name: 'CPU', value: 'Intel Core Ultra 9 185H (16 Nhân 22 Luồng, Up to 5.1GHz)'),
            SpecKeyModel(name: 'RAM', value: '32GB LPDDR5X 7467MHz Onboard'),
            SpecKeyModel(name: 'VGA', value: 'NVIDIA GeForce RTX 4080 12GB GDDR6 (115W TGP)'),
            SpecKeyModel(name: 'Ổ cứng', value: '1TB M.2 NVMe PCIe 4.0 SSD'),
          ],
        ),
        SpecGroupModel(
          id: 2,
          name: 'Màn hình & Hiển thị',
          specKeys: [
            SpecKeyModel(name: 'Kích thước', value: '16.0 inch 16:10'),
            SpecKeyModel(name: 'Độ phân giải', value: '2.5K (2560 x 1600) ROG Nebula OLED'),
            SpecKeyModel(name: 'Tần số quét', value: '240Hz / 0.2ms, G-Sync, 100% DCI-P3'),
          ],
        ),
      ],
    ),

    ProductModel(
      productId: 2,
      productName: 'Apple MacBook Pro 16 inch M3 Max (36GB / 1TB SSD)',
      price: 89990000,
      discountPercent: 5,
      finalPrice: 85490000,
      quantity: 8,
      imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
      categoryId: 1,
      categoryName: 'Laptop',
      description:
          'MacBook Pro 16 inch trang bị chip M3 Max mang đến hiệu năng tột bậc cho chuyên gia dựng phim, thiết kế đồ họa 3D và lập trình viên. Màn hình Liquid Retina XDR sống động, pin sử dụng bền bỉ đến 22 giờ liên tục.',
      additionalImages: [
        'https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?w=800',
      ],
      productColors: [
        ProductColorModel(id: 3, productId: 2, colorName: 'Đen Không Gian (Space Black)', colorCode: '#1E1E24', quantity: 4),
        ProductColorModel(id: 4, productId: 2, colorName: 'Bạc Cổ Điển (Silver)', colorCode: '#D8D8D8', quantity: 4),
      ],
      specGroups: [
        SpecGroupModel(
          id: 3,
          name: 'Cấu hình xử lý',
          specKeys: [
            SpecKeyModel(name: 'Chip', value: 'Apple M3 Max (14 nhân CPU, 30 nhân GPU)'),
            SpecKeyModel(name: 'RAM', value: '36GB Unified Memory'),
            SpecKeyModel(name: 'Ổ cứng', value: '1TB SSD siêu tốc'),
          ],
        ),
      ],
    ),

    ProductModel(
      productId: 3,
      productName: 'Laptop Gaming Lenovo Legion Pro 7i Gen 9 (RTX 4090)',
      price: 76990000,
      discountPercent: 12,
      finalPrice: 67751000,
      quantity: 5,
      imageUrl: 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=800',
      categoryId: 1,
      categoryName: 'Laptop',
      description:
          'Quái vật gaming Lenovo Legion Pro 7i Gen 9 sở hữu sức mạnh không đối thủ từ vi xử lý Intel Core i9-14900HX cùng GPU NVIDIA RTX 4090 16GB. Tản nhiệt Legion ColdFront Vapor buồng hơi tân tiến.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 5, productId: 3, colorName: 'Xám Onyx (Onyx Grey)', colorCode: '#333533', quantity: 5),
      ],
      specGroups: [
        SpecGroupModel(
          id: 4,
          name: 'Cấu hình phần cứng',
          specKeys: [
            SpecKeyModel(name: 'CPU', value: 'Intel Core i9-14900HX (24 Nhân 32 Luồng, Up to 5.8GHz)'),
            SpecKeyModel(name: 'RAM', value: '32GB DDR5 5600MHz (2x 16GB)'),
            SpecKeyModel(name: 'VGA', value: 'NVIDIA GeForce RTX 4090 16GB GDDR6 (175W TGP)'),
            SpecKeyModel(name: 'SSD', value: '2TB PCIe 4.0 NVMe M.2'),
          ],
        ),
      ],
    ),

    ProductModel(
      productId: 4,
      productName: 'Laptop Doanh Nhân Dell XPS 15 9530 OLED Touch',
      price: 48990000,
      discountPercent: 8,
      finalPrice: 45070000,
      quantity: 0, // Hết hàng để kiểm thử giao diện
      imageUrl: 'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800',
      categoryId: 1,
      categoryName: 'Laptop',
      description:
          'Dell XPS 15 9530 là biểu tượng của dòng laptop Windows cao cấp với thiết kế sợi carbon tinh xảo, viền màn hình InfinityEdge 3.5K OLED cảm ứng siêu mỏng và âm thanh vòm 4 loa Waves Nx 3D.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 6, productId: 4, colorName: 'Bạc Bạch Kim / Đen Carbon', colorCode: '#202020', quantity: 0),
      ],
      specGroups: [
        SpecGroupModel(
          id: 5,
          name: 'Cấu hình chi tiết',
          specKeys: [
            SpecKeyModel(name: 'CPU', value: 'Intel Core i7-13700H (14 Nhân 20 Luồng)'),
            SpecKeyModel(name: 'RAM', value: '16GB DDR5 4800MHz'),
            SpecKeyModel(name: 'VGA', value: 'NVIDIA GeForce RTX 4050 6GB GDDR6'),
            SpecKeyModel(name: 'Màn hình', value: '15.6 inch 3.5K (3456 x 2160) OLED Cảm ứng'),
          ],
        ),
      ],
    ),

    // --- PC & MÁY TRẠM ---
    ProductModel(
      productId: 5,
      productName: 'PC Gaming ROG Strix G16CH (i7 14700F / RTX 4070 Super)',
      price: 42990000,
      discountPercent: 15,
      finalPrice: 36541500,
      quantity: 10,
      imageUrl: 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=800',
      categoryId: 2,
      categoryName: 'PC & Máy trạm',
      description:
          'Dàn PC Gaming đồng bộ ROG Strix G16CH với hệ thống tản nhiệt nước AIO, hiệu năng bùng nổ từ RTX 4070 Super phục vụ mọi tựa game AAA ở độ phân giải 2K 4K max setting.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 7, productId: 5, colorName: 'Đen ROG Cyber (Aura RGB)', colorCode: '#121212', quantity: 10),
      ],
      specGroups: [
        SpecGroupModel(
          id: 6,
          name: 'Cấu hình hệ thống',
          specKeys: [
            SpecKeyModel(name: 'CPU', value: 'Intel Core i7-14700F (20 Nhân 28 Luồng)'),
            SpecKeyModel(name: 'VGA', value: 'ASUS Dual GeForce RTX 4070 Super 12GB'),
            SpecKeyModel(name: 'RAM', value: '32GB DDR5 5600MHz Kingston Fury'),
            SpecKeyModel(name: 'Nguồn', value: '750W 80 Plus Gold Modular'),
          ],
        ),
      ],
    ),

    ProductModel(
      productId: 6,
      productName: 'Máy Trạm Workstation Dell Precision 3660 Tower',
      price: 52000000,
      discountPercent: 0,
      finalPrice: 52000000,
      quantity: 6,
      imageUrl: 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=800',
      categoryId: 2,
      categoryName: 'PC & Máy trạm',
      description:
          'Máy trạm chuyên nghiệp phục vụ mô phỏng AI, dựng hình kiến trúc CAD/CAM và biên tập phim chuyên dụng, độ ổn định 24/7 với chứng nhận ISV toàn diện.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 8, productId: 6, colorName: 'Đen Nhám Doanh Nghiệp', colorCode: '#1F1F1F', quantity: 6),
      ],
      specGroups: [
        SpecGroupModel(
          id: 7,
          name: 'Thông số kỹ thuật',
          specKeys: [
            SpecKeyModel(name: 'CPU', value: 'Intel Core i9-13900K vPro (24 Nhân 32 Luồng)'),
            SpecKeyModel(name: 'VGA', value: 'NVIDIA RTX A4000 16GB GDDR6 ECC'),
            SpecKeyModel(name: 'RAM', value: '64GB DDR5 ECC Registered'),
            SpecKeyModel(name: 'Lưu trữ', value: '2TB NVMe SSD + 4TB HDD Enterprise'),
          ],
        ),
      ],
    ),

    // --- LINH KIỆN MÁY TÍNH ---
    ProductModel(
      productId: 7,
      productName: 'Card Màn Hình ASUS ROG Strix GeForce RTX 4090 OC 24GB',
      price: 59990000,
      discountPercent: 7,
      finalPrice: 55790000,
      quantity: 4,
      imageUrl: 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=800',
      categoryId: 3,
      categoryName: 'Linh kiện máy tính',
      description:
          'Đỉnh cao đồ họa thế giới với vi kiến trúc Ada Lovelace, 24GB VRAM GDDR6X, quạt công nghệ hướng trục Axial-tech tăng 23% lưu lượng gió cùng bộ khung kim loại đúc cực kỳ chắc chắn.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 9, productId: 7, colorName: 'Đen Xám Kim Loại', colorCode: '#1C1D21', quantity: 4),
      ],
      specGroups: [
        SpecGroupModel(
          id: 8,
          name: 'Thông số GPU',
          specKeys: [
            SpecKeyModel(name: 'CUDA Cores', value: '16384 Cores'),
            SpecKeyModel(name: 'Bộ nhớ', value: '24GB GDDR6X 384-bit'),
            SpecKeyModel(name: 'Nguồn khuyến nghị', value: '1000W trở lên'),
          ],
        ),
      ],
    ),

    ProductModel(
      productId: 8,
      productName: 'Bộ Vi Xử Lý CPU Intel Core i9-14900K Box Chính Hãng',
      price: 15490000,
      discountPercent: 5,
      finalPrice: 14715500,
      quantity: 20,
      imageUrl: 'https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=800',
      categoryId: 3,
      categoryName: 'Linh kiện máy tính',
      description:
          'CPU Intel Core i9 thế hệ 14 Raptor Lake Refresh với xung nhịp turbo đạt tới 6.0GHz ngay khi xuất xưởng, xử lý mượt mà mọi tác vụ nặng nề nhất.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 10, productId: 8, colorName: 'Xanh Intel Box', colorCode: '#0071C5', quantity: 20),
      ],
      specGroups: [
        SpecGroupModel(
          id: 9,
          name: 'Thông số vi xử lý',
          specKeys: [
            SpecKeyModel(name: 'Số nhân/luồng', value: '24 Nhân (8P + 16E) / 32 Luồng'),
            SpecKeyModel(name: 'Xung nhịp tối đa', value: 'Lên đến 6.0GHz Thermal Velocity Boost'),
            SpecKeyModel(name: 'Socket', value: 'LGA1700 (Hỗ trợ mainboard Z790, B760)'),
          ],
        ),
      ],
    ),

    // --- MÀN HÌNH MÁY TÍNH ---
    ProductModel(
      productId: 9,
      productName: 'Màn Hình Gaming OLED LG UltraGear 27GR95QE-B (27" 240Hz 0.03ms)',
      price: 21990000,
      discountPercent: 18,
      finalPrice: 18031800,
      quantity: 9,
      imageUrl: 'https://images.unsplash.com/photo-1527443224154-c4a3942d3acf?w=800',
      categoryId: 4,
      categoryName: 'Màn hình máy tính',
      description:
          'Màn hình OLED gaming 27 inch đầu tiên trên thế giới với tần số quét 240Hz và thời gian phản hồi thần tốc 0.03ms GtG, tương phản vô hạn với màu đen tuyệt đối.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 11, productId: 9, colorName: 'Đen Nhám Gaming', colorCode: '#181818', quantity: 9),
      ],
      specGroups: [
        SpecGroupModel(
          id: 10,
          name: 'Thông số màn hình',
          specKeys: [
            SpecKeyModel(name: 'Tấm nền', value: 'OLED 27 inch 16:9 QHD (2560 x 1440)'),
            SpecKeyModel(name: 'Tần số quét', value: '240Hz, 0.03ms GtG'),
            SpecKeyModel(name: 'Đồng bộ', value: 'NVIDIA G-Sync Compatible, AMD FreeSync Premium'),
          ],
        ),
      ],
    ),

    // --- BÀN PHÍM & CHUỘT ---
    ProductModel(
      productId: 10,
      productName: 'Bàn Phím Cơ Không Dây ASUS ROG Azoth 75% OLED RGB',
      price: 6490000,
      discountPercent: 10,
      finalPrice: 5841000,
      quantity: 15,
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800',
      categoryId: 5,
      categoryName: 'Bàn phím & Chuột',
      description:
          'Bàn phím cơ Custom cao cấp layout 75%, tích hợp màn hình OLED 2 inch hiển thị thông số và núm xoay điều khiển 3 hướng. Đệm silicone giảm chấn 3 lớp êm ái, switch ROG NX lube sẵn.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 12, productId: 10, colorName: 'Xám Đen Không Gian', colorCode: '#252627', quantity: 8),
        ProductColorModel(id: 13, productId: 10, colorName: 'Trắng Tuyết (Moonlight White)', colorCode: '#F0F0F0', quantity: 7),
      ],
      specGroups: [
        SpecGroupModel(
          id: 11,
          name: 'Đặc tính bàn phím',
          specKeys: [
            SpecKeyModel(name: 'Switch', value: 'ROG NX Red Linear (Hot-swappable)'),
            SpecKeyModel(name: 'Kết nối', value: 'Bluetooth 5.1, 2.4GHz SpeedNova, Type-C'),
            SpecKeyModel(name: 'Thời lượng pin', value: 'Hơn 2000 giờ (tắt RGB & OLED)'),
          ],
        ),
      ],
    ),

    ProductModel(
      productId: 11,
      productName: 'Chuột Gaming Siêu Nhẹ Logitech G Pro X Superlight 2 (60g)',
      price: 3690000,
      discountPercent: 8,
      finalPrice: 3394800,
      quantity: 18,
      imageUrl: 'https://images.unsplash.com/photo-1615663245857-ac93bb7c39e7?w=800',
      categoryId: 5,
      categoryName: 'Bàn phím & Chuột',
      description:
          'Huyền thoại Esports phiên bản 2 với mắt đọc cảm biến HERO 2 độ chính xác hơn 32.000 DPI, switch lai quang cơ LIGHTFORCE siêu bền và trọng lượng vỏn vẹn chỉ 60 gram.',
      additionalImages: [],
      productColors: [
        ProductColorModel(id: 14, productId: 11, colorName: 'Đen Nhám (Black)', colorCode: '#111111', quantity: 8),
        ProductColorModel(id: 15, productId: 11, colorName: 'Trắng Ngọc (White)', colorCode: '#F5F5F5', quantity: 6),
        ProductColorModel(id: 16, productId: 11, colorName: 'Hồng Magenta', colorCode: '#E20074', quantity: 4),
      ],
      specGroups: [
        SpecGroupModel(
          id: 12,
          name: 'Thông số cảm biến',
          specKeys: [
            SpecKeyModel(name: 'Cảm biến', value: 'HERO 2 (100 - 32.000 DPI, 500+ IPS)'),
            SpecKeyModel(name: 'Tần số phản hồi', value: 'Polling rate 2000Hz (0.5ms)'),
            SpecKeyModel(name: 'Trọng lượng', value: '60 gram siêu nhẹ'),
          ],
        ),
      ],
    ),
  ];

  /// Lọc sản phẩm theo Category và từ khóa tìm kiếm
  static PaginatedResponse<ProductModel> filterProducts({
    int? categoryId,
    String? q,
    int page = 1,
    int pageSize = 10,
  }) {
    var list = products.toList();

    if (categoryId != null && categoryId > 0) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }

    if (q != null && q.trim().isNotEmpty) {
      final queryLower = q.trim().toLowerCase();
      list = list
          .where((p) =>
              p.productName.toLowerCase().contains(queryLower) ||
              (p.categoryName != null &&
                  p.categoryName!.toLowerCase().contains(queryLower)))
          .toList();
    }

    final total = list.length;
    final startIndex = (page - 1) * pageSize;
    final items = (startIndex < total)
        ? list.skip(startIndex).take(pageSize).toList()
        : <ProductModel>[];

    final totalPages = (total / pageSize).ceil();

    return PaginatedResponse<ProductModel>(
      items: items,
      totalItems: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  /// Tìm sản phẩm theo ID
  static ProductModel? findProductById(int productId) {
    try {
      return products.firstWhere((p) => p.productId == productId);
    } catch (_) {
      return products.isNotEmpty ? products.first : null;
    }
  }
}
