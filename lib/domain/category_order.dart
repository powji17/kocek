import '../data/models/category.dart';
import '../data/models/default_categories.dart';

/// true bila kategori ini adalah "Lainnya" (penampung). Tidak bisa diubah
/// atau dihapus karena menjadi tujuan transaksi dari kategori yang dihapus.
bool isFallbackCategory(Category c) {
  return c.id == DefaultCategories.fallbackExpenseId ||
      c.id == DefaultCategories.fallbackIncomeId;
}

/// Urutan tampil kategori: bawaan sesuai urutan aslinya, lalu kategori
/// buatan pengguna (A-Z), dan "Lainnya" selalu di akhir.
List<Category> sortCategories(List<Category> input) {
  final defaultOrder = <String, int>{
    for (var i = 0; i < DefaultCategories.all.length; i++)
      DefaultCategories.all[i].id: i,
  };

  int rank(Category c) {
    if (isFallbackCategory(c)) return 1000;
    return defaultOrder[c.id] ?? 100;
  }

  final list = [...input];
  list.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return list;
}
