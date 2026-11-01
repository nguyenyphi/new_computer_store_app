/// Model thuộc tính thông số kỹ thuật (SpecKey)
class SpecKeyModel {
  final int? id;
  final String name;
  final String value;

  SpecKeyModel({
    this.id,
    required this.name,
    required this.value,
  });

  factory SpecKeyModel.fromJson(Map<String, dynamic> json) {
    return SpecKeyModel(
      id: json['specKeyId'] != null
          ? (json['specKeyId'] as num).toInt()
          : (json['id'] != null ? (json['id'] as num).toInt() : null),
      name: json['name'] as String? ??
          (json['specKey'] is Map ? json['specKey']['name'] as String? ?? '' : ''),
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }
}

/// Model nhóm thông số kỹ thuật (SpecGroup) để hiển thị trong ExpansionTile
class SpecGroupModel {
  final int id;
  final String name;
  final int displayOrder;
  final List<SpecKeyModel> specKeys;

  SpecGroupModel({
    required this.id,
    required this.name,
    this.displayOrder = 0,
    required this.specKeys,
  });

  factory SpecGroupModel.fromJson(Map<String, dynamic> json) {
    List<SpecKeyModel> keys = [];
    final rawSpecs = json['specs'] ?? json['specKeys'];
    if (rawSpecs is List) {
      keys = rawSpecs
          .map((item) => SpecKeyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return SpecGroupModel(
      id: json['groupId'] != null
          ? (json['groupId'] as num).toInt()
          : (json['id'] != null ? (json['id'] as num).toInt() : 0),
      name: json['groupName'] as String? ??
          json['name'] as String? ??
          'Thông số kỹ thuật',
      displayOrder: json['displayOrder'] != null
          ? (json['displayOrder'] as num).toInt()
          : 0,
      specKeys: keys,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayOrder': displayOrder,
      'specKeys': specKeys.map((e) => e.toJson()).toList(),
    };
  }
}
