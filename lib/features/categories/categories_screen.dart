import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/money_transaction.dart';
import '../../data/providers.dart';
import '../../domain/category_order.dart';
import 'category_form_sheet.dart';

/// Kelola kategori (PRD F5): tambah, ubah nama, ganti ikon, dan hapus.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryType _type = CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all = ref.watch(categoriesProvider).value ?? const <Category>[];
    final transactions =
        ref.watch(transactionsProvider).value ?? const <MoneyTransaction>[];

    final usage = <String, int>{};
    for (final t in transactions) {
      final id = t.categoryId;
      if (id != null) usage[id] = (usage[id] ?? 0) + 1;
    }

    final categories = sortCategories(
      all.where((c) => c.type == _type).toList(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola kategori')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SegmentedButton<CategoryType>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: CategoryType.expense,
                  label: Text('Pengeluaran'),
                ),
                ButtonSegment(
                  value: CategoryType.income,
                  label: Text('Pemasukan'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada kategori.',
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = categories[i];
                      final locked = isFallbackCategory(c);
                      final color = Color(c.colorValue);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconForKey(c.iconKey), color: color),
                          ),
                          title: Text(
                            c.name,
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            locked
                                ? 'Penampung kategori yang dihapus'
                                : '${usage[c.id] ?? 0} transaksi',
                          ),
                          trailing: Icon(
                            locked
                                ? Icons.lock_outline_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          onTap: locked
                              ? null
                              : () => showCategoryFormSheet(
                                    context,
                                    type: _type,
                                    existing: c,
                                  ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryFormSheet(context, type: _type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah kategori'),
      ),
    );
  }
}
