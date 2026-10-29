import 'enums.dart';

/// Kategori pemasukan/pengeluaran (PRD F5).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String iconKey;

  /// Warna ARGB, contoh 0xFFF97316.
  final int colorValue;
  final CategoryType type;
  final bool isDefault;

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? 'more_horiz',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF9CA3AF,
      type: CategoryType.fromValue(map['type'] as String?),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'type': type.value,
        'isDefault': isDefault,
      };

  Category copyWith({String? name, String? iconKey, int? colorValue}) {
    return Category(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      type: type,
      isDefault: isDefault,
    );
  }
}
