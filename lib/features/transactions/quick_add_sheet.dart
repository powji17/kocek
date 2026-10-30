import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../../domain/category_order.dart';

/// Membuka formulir pencatatan cepat (PRD F3).
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const QuickAddSheet(),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  static const int _maxAmount = 999999999999;

  TransactionType _type = TransactionType.expense;
  int _amount = 0;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _showNote = false;
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyDefaults();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // ---------- Default cerdas ----------

  List<Wallet> _readActiveWallets() {
    final all = ref.read(walletsProvider).value ?? const <Wallet>[];
    return all.where((w) => w.active).toList();
  }

  CategoryType get _categoryType =>
      _type == TransactionType.income ? CategoryType.income : CategoryType.expense;

  /// Dompet dan kategori mengikuti transaksi terakhir dengan tipe yang sama,
  /// sehingga kasus umum cukup: ketik nominal lalu Simpan.
  void _applyDefaults() {
    final wallets = _readActiveWallets();
    final ids = wallets.map((w) => w.id).toSet();
    final transactions =
        ref.read(transactionsProvider).value ?? const <MoneyTransaction>[];

    MoneyTransaction? last;
    for (final t in transactions) {
      if (t.type == _type) {
        last = t;
        break;
      }
    }

    final firstWallet = wallets.isEmpty ? null : wallets.first.id;
    final lastWallet = last?.walletId;
    _walletId =
        (lastWallet != null && ids.contains(lastWallet)) ? lastWallet : firstWallet;

    if (_type == TransactionType.transfer) {
      final lastTo = last?.toWalletId;
      if (lastTo != null && ids.contains(lastTo) && lastTo != _walletId) {
        _toWalletId = lastTo;
      } else {
        _toWalletId = _firstOtherWallet(wallets, _walletId);
      }
      _categoryId = null;
    } else {
      final categories = ref.read(categoriesProvider).value ?? const <Category>[];
      final ofType = sortCategories(
        categories.where((c) => c.type == _categoryType).toList(),
      );
      final catIds = ofType.map((c) => c.id).toSet();
      final lastCat = last?.categoryId;
      if (lastCat != null && catIds.contains(lastCat)) {
        _categoryId = lastCat;
      } else {
        _categoryId = ofType.isEmpty ? null : ofType.first.id;
      }
      _toWalletId = null;
    }
  }

  String? _firstOtherWallet(List<Wallet> wallets, String? excludeId) {
    for (final w in wallets) {
      if (w.id != excludeId) return w.id;
    }
    return null;
  }

  // ---------- Aksi ----------

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'back') {
        _amount = _amount ~/ 10;
      } else if (key == '000') {
        _amount = _guard(_amount * 1000);
      } else {
        _amount = _guard(_amount * 10 + int.parse(key));
      }
    });
  }

  int _guard(int next) => next > _maxAmount ? _amount : next;

  void _selectWallet(String id) {
    setState(() {
      _walletId = id;
      if (_type == TransactionType.transfer && _toWalletId == id) {
        _toWalletId = _firstOtherWallet(_readActiveWallets(), id);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool get _canSave {
    if (_amount <= 0 || _walletId == null) return false;
    if (_type == TransactionType.transfer) {
      return _toWalletId != null && _toWalletId != _walletId;
    }
    return true;
  }

  String get _savedLabel {
    switch (_type) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
      case TransactionType.transfer:
        return 'Pindah dana';
      case TransactionType.goalDeposit:
        return 'Setoran';
    }
  }

  Color get _typeColor {
    switch (_type) {
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.transfer:
      case TransactionType.goalDeposit:
        return AppColors.primary;
    }
  }

  void _save() {
    final repo = ref.read(transactionRepositoryProvider);
    if (repo == null || !_canSave) return;

    final now = DateTime.now();
    // Hari ini memakai jam sekarang (urutan rapi); tanggal lain jam 12 siang.
    final date = isSameDay(_date, now)
        ? now
        : DateTime(_date.year, _date.month, _date.day, 12);
    final isTransfer = _type == TransactionType.transfer;

    final tx = MoneyTransaction(
      id: repo.newId(),
      type: _type,
      amount: _amount,
      walletId: _walletId!,
      toWalletId: isTransfer ? _toWalletId : null,
      categoryId: isTransfer ? null : _categoryId,
      note: _note.text.trim(),
      date: date,
    );

    // Tidak di-await (offline-first): tampilan sudah berubah lewat stream lokal.
    unawaited(repo.add(tx).catchError((Object _) {}));

    final messenger = ScaffoldMessenger.of(context);
    final label = _savedLabel;
    final amount = _amount;
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label ${formatRupiah(amount)} tersimpan'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Urungkan',
            textColor: AppColors.primarySoft,
            onPressed: () {
              unawaited(repo.delete(tx.id).catchError((Object _) {}));
            },
          ),
        ),
      );
  }

  // ---------- Tampilan ----------

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final wallets = (ref.watch(walletsProvider).value ?? const <Wallet>[])
        .where((w) => w.active)
        .toList();
    final categories = sortCategories(
      (ref.watch(categoriesProvider).value ?? const <Category>[])
          .where((c) => c.type == _categoryType)
          .toList(),
    );
    final isTransfer = _type == TransactionType.transfer;

    if (wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Text(
          'Belum ada dompet aktif. Tambah atau aktifkan dompet dulu di '
          'Pengaturan > Kelola dompet.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    Widget pad(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        );

    Widget label(String value) => pad(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              value,
              style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        );

    Widget walletChips({
      required String? selectedId,
      required ValueChanged<String> onSelect,
      String? disabledId,
    }) {
      return pad(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in wallets)
              ChoiceChip(
                showCheckmark: false,
                avatar: Icon(iconForKey(w.iconKey), size: 18),
                label: Text(w.name),
                selected: selectedId == w.id,
                onSelected: w.id == disabledId ? null : (_) => onSelect(w.id),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pad(
              SegmentedButton<TransactionType>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Keluar'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Masuk'),
                  ),
                  ButtonSegment(
                    value: TransactionType.transfer,
                    label: Text('Pindah'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    _applyDefaults();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            pad(
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatRupiah(_amount),
                    style: AppTheme.numeric(text.displaySmall).copyWith(
                      fontWeight: FontWeight.w800,
                      color: _typeColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            label(isTransfer ? 'Dari' : 'Dompet'),
            walletChips(
              selectedId: _walletId,
              onSelect: _selectWallet,
            ),
            if (isTransfer) ...[
              const SizedBox(height: 12),
              label('Ke'),
              if (wallets.length < 2)
                pad(
                  Text(
                    'Butuh minimal 2 dompet aktif untuk memindahkan uang.',
                    style: text.bodySmall?.copyWith(color: AppColors.expense),
                  ),
                )
              else
                walletChips(
                  selectedId: _toWalletId,
                  disabledId: _walletId,
                  onSelect: (id) => setState(() => _toWalletId = id),
                ),
            ] else ...[
              const SizedBox(height: 12),
              label('Kategori'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        iconForKey(c.iconKey),
                        size: 18,
                        color: Color(c.colorValue),
                      ),
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            pad(
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.event_outlined, size: 18),
                    label: Text(formatDateLabel(_date)),
                    onPressed: _pickDate,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.notes_outlined, size: 18),
                    label: Text(_showNote ? 'Sembunyikan catatan' : 'Catatan'),
                    onPressed: () => setState(() => _showNote = !_showNote),
                  ),
                ],
              ),
            ),
            if (_showNote) ...[
              const SizedBox(height: 12),
              pad(
                TextField(
                  controller: _note,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(children: [_key('1'), _key('2'), _key('3')]),
                  Row(children: [_key('4'), _key('5'), _key('6')]),
                  Row(children: [_key('7'), _key('8'), _key('9')]),
                  Row(
                    children: [
                      _key('000'),
                      _key('0'),
                      _key('back', icon: Icons.backspace_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            pad(
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: const Text('Simpan'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _key(String value, {IconData? icon}) {
    return _NumKey(
      label: value,
      icon: icon,
      semanticLabel: value == 'back' ? 'Hapus satu angka' : value,
      onTap: () => _press(value),
    );
  }
}

/// Tombol angka besar pada numpad.
class _NumKey extends StatelessWidget {
  const _NumKey({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String semanticLabel;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          button: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: Material(
            color: AppColors.divider.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox(
                height: 52,
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: AppColors.textPrimary)
                      : Text(
                          label,
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
