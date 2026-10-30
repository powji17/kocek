import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../data/models/category.dart';
import '../../data/models/default_categories.dart';
import '../../data/models/enums.dart';
import '../../data/models/money_transaction.dart';
import '../../data/providers.dart';

/// Bottom sheet tambah / ubah kategori (PRD F5). [existing] null = tambah baru.
Future<void> showCategoryFormSheet(
  BuildContext context, {
  required CategoryType type,
  Category? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => CategoryFormSheet(type: type, existing: existing),
  );
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.type, this.existing});

  final CategoryType type;
  final Category? existing;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _iconKey = widget.existing?.iconKey ?? categoryIconKeys.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final all = ref.read(categoriesProvider).value ?? const <Category>[];
    final existing = widget.existing;

    if (name.isEmpty) {
      setState(() => _error = 'Nama kategori tidak boleh kosong.');
      return;
    }
    final duplicate = all.any(
      (c) =>
          c.type == widget.type &&
          c.id != existing?.id &&
          c.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _error = 'Sudah ada kategori dengan nama itu.');
      return;
    }

    final repo = ref.read(categoryRepositoryProvider);
    if (repo == null) return;

    final Category category;
    if (existing != null) {
      category = existing.copyWith(name: name, iconKey: _iconKey);
    } else {
      final sameType = all.where((c) => c.type == widget.type).length;
      category = Category(
        id: repo.newId(),
        name: name,
        iconKey: _iconKey,
        colorValue: categoryColorPalette[sameType % categoryColorPalette.length],
        type: widget.type,
      );
    }

    // Tidak di-await (offline-first).
    unawaited(repo.save(category).catchError((Object _) {}));
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    final repo = ref.read(categoryRepositoryProvider);
    if (existing == null || repo == null) return;

    final transactions =
        ref.read(transactionsProvider).value ?? const <MoneyTransaction>[];
    final usage = transactions.where((t) => t.categoryId == existing.id).length;
    final fallbackId = widget.type == CategoryType.income
        ? DefaultCategories.fallbackIncomeId
        : DefaultCategories.fallbackExpenseId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus kategori "${existing.name}"?'),
        content: Text(
          usage == 0
              ? 'Kategori ini belum dipakai transaksi mana pun.'
              : '$usage transaksi memakai kategori ini. Transaksinya akan '
                  'dipindahkan ke "Lainnya".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    unawaited(
      repo
          .deleteAndReassign(categoryId: existing.id, fallbackId: fallbackId)
          .catchError((Object _) {}),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isEdit = widget.existing != null;
    final typeLabel =
        widget.type == CategoryType.income ? 'pemasukan' : 'pengeluaran';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit
                        ? 'Ubah kategori'
                        : 'Tambah kategori $typeLabel',
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (isEdit)
                  TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.expense,
                    ),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(color: AppColors.expense),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: const InputDecoration(labelText: 'Nama kategori'),
            ),
            const SizedBox(height: 16),
            Text(
              'Ikon',
              style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in categoryIconKeys)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Icon(iconForKey(key), size: 20),
                    selected: _iconKey == key,
                    onSelected: (_) => setState(() => _iconKey = key),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: AppColors.expense),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
