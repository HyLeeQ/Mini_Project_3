class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String colorHex;
  final CategoryType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.type,
  });

  /// ============ TO JSON ============
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorHex': colorHex,
      'type': type.name, // enum -> String
    };
  }

  /// ============ FROM JSON ============
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      colorHex: json['colorHex'] ?? '',

      /// String -> enum
      type: CategoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CategoryType.expense,
      ),
    );
  }
}

enum CategoryType { income, expense }
