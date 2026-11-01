/// Model phân trang dữ liệu dùng chung (Paginated Response)
class PaginatedResponse<T> {
  final List<T> items;
  final int totalItems;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    this.totalItems = 0,
    this.page = 1,
    this.pageSize = 10,
    this.totalPages = 1,
  });

  /// Kiểm tra xem còn trang tiếp theo để cuộn vô hạn hay không
  bool get hasMore => page < totalPages;

  factory PaginatedResponse.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    if (json is List) {
      // Server trả trực tiếp mảng danh sách
      final list = json
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList();
      return PaginatedResponse<T>(
        items: list,
        totalItems: list.length,
        page: 1,
        pageSize: list.length,
        totalPages: 1,
      );
    }

    if (json is Map<String, dynamic>) {
      // Server trả Object phân trang
      final rawList = (json['items'] ?? json['data'] ?? []) as List;
      final list = rawList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList();

      final total = json['totalItems'] != null
          ? (json['totalItems'] as num).toInt()
          : (json['total'] != null ? (json['total'] as num).toInt() : list.length);

      final p = json['page'] != null
          ? (json['page'] as num).toInt()
          : (json['pageIndex'] != null ? (json['pageIndex'] as num).toInt() : 1);

      final ps = json['pageSize'] != null
          ? (json['pageSize'] as num).toInt()
          : 10;

      final tp = json['totalPages'] != null
          ? (json['totalPages'] as num).toInt()
          : (total > 0 && ps > 0 ? (total / ps).ceil() : 1);

      return PaginatedResponse<T>(
        items: list,
        totalItems: total,
        page: p,
        pageSize: ps,
        totalPages: tp,
      );
    }

    return PaginatedResponse<T>(items: []);
  }
}
