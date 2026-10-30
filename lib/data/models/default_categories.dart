import 'category.dart';
import 'enums.dart';

/// Kategori bawaan (PRD F5). ID-nya tetap (bukan acak) supaya kalau proses
/// pengisian awal terjadi dua kali, datanya tertimpa, bukan dobel.
class DefaultCategories {
  DefaultCategories._();

  /// Kategori "Lainnya" menjadi penampung saat kategori lain dihapus (PRD F5).
  static const String fallbackExpenseId = 'exp-lainnya';
  static const String fallbackIncomeId = 'inc-lainnya';

  static const List<Category> all = [
    // Pengeluaran
    Category(id: 'exp-makan', name: 'Makan', iconKey: 'restaurant', colorValue: 0xFFF97316, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-jajan', name: 'Jajan', iconKey: 'fastfood', colorValue: 0xFFEC4899, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-transport', name: 'Transport', iconKey: 'directions_bus', colorValue: 0xFF3B82F6, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-pulsa-data', name: 'Pulsa & Data', iconKey: 'smartphone', colorValue: 0xFF8B5CF6, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-belanja', name: 'Belanja', iconKey: 'shopping_bag', colorValue: 0xFF14B8A6, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-hiburan', name: 'Hiburan', iconKey: 'movie', colorValue: 0xFFEAB308, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-pendidikan', name: 'Pendidikan', iconKey: 'school', colorValue: 0xFF6366F1, type: CategoryType.expense, isDefault: true),
    Category(id: 'exp-lainnya', name: 'Lainnya', iconKey: 'more_horiz', colorValue: 0xFF9CA3AF, type: CategoryType.expense, isDefault: true),
    // Pemasukan
    Category(id: 'inc-uang-saku', name: 'Uang Saku', iconKey: 'savings', colorValue: 0xFF16A34A, type: CategoryType.income, isDefault: true),
    Category(id: 'inc-gaji', name: 'Gaji', iconKey: 'work', colorValue: 0xFF059669, type: CategoryType.income, isDefault: true),
    Category(id: 'inc-hadiah', name: 'Hadiah', iconKey: 'card_giftcard', colorValue: 0xFFF59E0B, type: CategoryType.income, isDefault: true),
    Category(id: 'inc-lainnya', name: 'Lainnya', iconKey: 'more_horiz', colorValue: 0xFF9CA3AF, type: CategoryType.income, isDefault: true),
  ];
}
