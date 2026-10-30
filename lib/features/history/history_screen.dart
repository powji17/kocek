import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/dates.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/goal.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../../domain/category_order.dart';
import '../../domain/transaction_filter.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../transactions/quick_add_sheet.dart';

/// Hasil pilihan di sheet filter; value null berarti "Semua" (hapus filter).
class _PickResult<T> {
  const _PickResult(this.value);

  final T? value;
}

class _Option<T> {
  const _Option(this.label, this.value);

  final String label;
  final T value;
}

/// Riwayat transaksi (PRD F7): dikelompokkan per tanggal, terbaru di atas,
/// dengan filter (tanggal, tipe, dompet, kategori), pencarian catatan, serta
/// ubah dan hapus lewat tap atau geser.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  TransactionFilter _filter = const TransactionFilter();
  final TextEditingController _search = TextEditingController();

  /// Transaksi yang baru digeser-hapus. Disembunyikan seketika supaya
  /// Dismissible langsung lepas dari pohon widget, tanpa menunggu stream.
  final Set<String> _removedIds = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _typeLabel(TransactionType t) {
    switch (t) {
      case TransactionType.expense:
        return 'Keluar';
      case TransactionType.income:
        return 'Masuk';
      case TransactionType.transfer:
        return 'Pindah';
      case TransactionType.goalDeposit:
        return 'Setor Target';
    }
  }

  void _reset() {
    _search.clear();
    setState(() => _filter = const TransactionFilter());
  }

  // ---------- Pemilih filter ----------

  Future<void> _pickRange() async {
    final current = _filter.hasRange
        ? DateTimeRange(start: _filter.from!, end: _filter.to!)
        : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: current,
      helpText: 'Pilih rentang tanggal',
      saveText: 'Terapkan',
    );
    if (picked != null) {
      setState(() => _filter = _filter.withRange(picked.start, picked.end));
    }
  }

  Future<_PickResult<T>?> _pickOne<T>({
    required String title,
    required T? current,
    required List<_Option<T>> options,
  }) {
    return showModalBottomSheet<_PickResult<T>>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              title: const Text('Semua'),
              trailing: current == null
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(_PickResult<T>(null)),
            ),
            for (final o in options)
              ListTile(
                title: Text(o.label),
                trailing: current == o.value
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(_PickResult<T>(o.value)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickType() async {
    final result = await _pickOne<TransactionType>(
      title: 'Tipe transaksi',
      current: _filter.type,
      options: [
        for (final t in TransactionType.values) _Option(_typeLabel(t), t),
      ],
    );
    if (result != null) {
      setState(() => _filter = _filter.withType(result.value));
    }
  }

  Future<void> _pickWallet(List<Wallet> wallets) async {
    final result = await _pickOne<String>(
      title: 'Dompet',
      current: _filter.walletId,
      options: [for (final w in wallets) _Option(w.name, w.id)],
    );
    if (result != null) {
      setState(() => _filter = _filter.withWallet(result.value));
    }
  }

  Future<void> _pickCategory(List<Category> categories) async {
    final expense = sortCategories(
      categories.where((c) => c.type == CategoryType.expense).toList(),
    );
    final income = sortCategories(
      categories.where((c) => c.type == CategoryType.income).toList(),
    );

    final result = await showModalBottomSheet<_PickResult<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final text = Theme.of(context).textTheme;

        Widget header(String title) => Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                title,
                style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
              ),
            );

        Widget row(Category c) => ListTile(
              leading: Icon(iconForKey(c.iconKey), color: Color(c.colorValue)),
              title: Text(c.name),
              trailing: _filter.categoryId == c.id
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(_PickResult<String>(c.id)),
            );

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Text(
                  'Kategori',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                title: const Text('Semua'),
                trailing: _filter.categoryId == null
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(_PickResult<String>(null)),
              ),
              header('Pengeluaran'),
              for (final c in expense) row(c),
              header('Pemasukan'),
              for (final c in income) row(c),
            ],
          ),
        );
      },
    );
    if (result != null) {
      setState(() => _filter = _filter.withCategory(result.value));
    }
  }

  // ---------- Hapus lewat geser ----------

  Future<bool> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi ini?'),
        content: const Text(
          'Saldo dompet dan total tabungan akan dihitung ulang.',
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
    return ok == true;
  }

  // ---------- Tampilan ----------

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final all =
        ref.watch(transactionsProvider).value ?? const <MoneyTransaction>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];

    final categoryMap = {for (final c in categories) c.id: c};
    final walletMap = {for (final w in wallets) w.id: w};
    final goalMap = {for (final g in goals) g.id: g};

    final visible = all.where((t) => !_removedIds.contains(t.id)).toList();
    final groups = groupByDay(_filter.apply(visible));

    Widget chip({
      required String label,
      required bool active,
      required VoidCallback onTap,
      required VoidCallback onClear,
    }) {
      return InputChip(
        showCheckmark: false,
        label: Text(label),
        selected: active,
        onPressed: onTap,
        onDeleted: active ? onClear : null,
      );
    }

    final walletName = walletMap[_filter.walletId]?.name ?? 'Dompet';
    final categoryName = categoryMap[_filter.categoryId]?.name ?? 'Kategori';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (value) =>
                setState(() => _filter = _filter.withQuery(value)),
            decoration: InputDecoration(
              hintText: 'Cari catatan',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        setState(() => _filter = _filter.withQuery(''));
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              chip(
                label: _filter.hasRange
                    ? formatRangeLabel(_filter.from!, _filter.to!)
                    : 'Tanggal',
                active: _filter.hasRange,
                onTap: _pickRange,
                onClear: () =>
                    setState(() => _filter = _filter.withRange(null, null)),
              ),
              const SizedBox(width: 8),
              chip(
                label: _filter.type == null ? 'Tipe' : _typeLabel(_filter.type!),
                active: _filter.type != null,
                onTap: _pickType,
                onClear: () => setState(() => _filter = _filter.withType(null)),
              ),
              const SizedBox(width: 8),
              chip(
                label: _filter.walletId == null ? 'Dompet' : walletName,
                active: _filter.walletId != null,
                onTap: () => _pickWallet(wallets),
                onClear: () =>
                    setState(() => _filter = _filter.withWallet(null)),
              ),
              const SizedBox(width: 8),
              chip(
                label: _filter.categoryId == null ? 'Kategori' : categoryName,
                active: _filter.categoryId != null,
                onTap: () => _pickCategory(categories),
                onClear: () =>
                    setState(() => _filter = _filter.withCategory(null)),
              ),
              if (_filter.isActive) ...[
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset'),
                  onPressed: _reset,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Belum ada transaksi. Tap Catat di Beranda untuk mulai.',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : groups.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Tidak ada transaksi yang cocok dengan filter.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: groups.length,
                      itemBuilder: (context, i) => _buildGroup(
                        context,
                        groups[i],
                        categoryMap,
                        walletMap,
                        goalMap,
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildGroup(
    BuildContext context,
    DayGroup group,
    Map<String, Category> categoryMap,
    Map<String, Wallet> walletMap,
    Map<String, Goal> goalMap,
  ) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              formatDateHeader(group.day),
              style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0) const Divider(),
                  _buildRow(
                    context,
                    group.items[i],
                    categoryMap,
                    walletMap,
                    goalMap,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    MoneyTransaction tx,
    Map<String, Category> categoryMap,
    Map<String, Wallet> walletMap,
    Map<String, Goal> goalMap,
  ) {
    return Dismissible(
      key: ValueKey(tx.id),
      // Geser ke kanan = ubah, geser ke kiri = hapus (dengan konfirmasi).
      background: Container(
        color: AppColors.primarySoft,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.edit_outlined, color: AppColors.primaryDark),
      ),
      secondaryBackground: Container(
        color: AppColors.expense.withValues(alpha: 0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          unawaited(showEditTransactionSheet(context, tx));
          return false;
        }
        return _confirmDelete();
      },
      onDismissed: (_) {
        setState(() => _removedIds.add(tx.id));
        final repo = ref.read(transactionRepositoryProvider);
        if (repo != null) {
          unawaited(repo.delete(tx.id).catchError((Object _) {}));
        }
      },
      // Material berlatar agar warna geser tidak tembus ke teks.
      child: Material(
        color: AppColors.surface,
        child: TransactionTile(
          transaction: tx,
          categories: categoryMap,
          wallets: walletMap,
          goals: goalMap,
          onTap: () => unawaited(showEditTransactionSheet(context, tx)),
        ),
      ),
    );
  }
}
