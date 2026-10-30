import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/data/models/category.dart';
import 'package:kocek/data/models/default_categories.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/domain/category_order.dart';

void main() {
  final expense = DefaultCategories.all
      .where((c) => c.type == CategoryType.expense)
      .toList();

  test('kategori bawaan tampil sesuai urutan aslinya, Lainnya di akhir', () {
    // Sengaja diacak dulu.
    final shuffled = [...expense]..shuffle();
    final names = sortCategories(shuffled).map((c) => c.name).toList();
    expect(names, [
      'Makan',
      'Jajan',
      'Transport',
      'Pulsa & Data',
      'Belanja',
      'Hiburan',
      'Pendidikan',
      'Lainnya',
    ]);
  });

  test('kategori buatan pengguna berada sebelum Lainnya, urut A-Z', () {
    const kopi = Category(
      id: 'k1',
      name: 'Kopi',
      iconKey: 'restaurant',
      colorValue: 0xFF000000,
      type: CategoryType.expense,
    );
    const arisan = Category(
      id: 'k2',
      name: 'Arisan',
      iconKey: 'savings',
      colorValue: 0xFF000000,
      type: CategoryType.expense,
    );
    final names = sortCategories([...expense, kopi, arisan])
        .map((c) => c.name)
        .toList();
    expect(names.sublist(names.length - 3), ['Arisan', 'Kopi', 'Lainnya']);
    expect(names.first, 'Makan');
  });
}
