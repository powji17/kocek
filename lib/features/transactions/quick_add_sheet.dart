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
import '../../data/models/goal.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../../domain/category_order.dart';
import '../goals/goal_actions.dart';

/// Membuka formulir pencatatan cepat (PRD F3). [initialType] dan
/// [initialGoalId] dipakai tombol "Setor" pada kartu target.
Future<void> showQuickAddSheet(
  BuildContext context, {
  TransactionType? initialType,
  String? initialGoalId,
}) {
  return _showSheet(
    context,
    initialType: initialType,
    initialGoalId: initialGoalId,
  );
}

/// Membuka formulir yang sama untuk mengubah transaksi (PRD F7).
Future<void> showEditTransactionSheet(
  BuildContext context,
  MoneyTransaction transaction,
) {
  return _showSheet(context, editing: transaction);
}

Future<void> _showSheet(
  BuildContext context, {
  MoneyTransaction? editing,
  TransactionType? initialType,
  String? initialGoalId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => QuickAddSheet(
      editing: editing,
      initialType: initialType,
      initialGoalId: initialGoalId,
    ),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({
    super.key,
    this.editing,
    this.initialType,
    this.initialGoalId,
  });

  /// null = transaksi baru, selain itu = mengubah transaksi ini.
  final MoneyTransaction? editing;
  final TransactionType? initialType;
  final String? initialGoalId;

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

  /// Setor target: target tujuan (wajib). Keluar: target yang ditautkan (opsional).
  String? _goalId;
  DateTime _date = DateTime.now();
  bool _dateChanged = false;
  bool _showNote = false;
  final TextEditingController _note = TextEditingController();

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e == null) {
      _type = widget.initialType ?? TransactionType.expense;
      _applyDefaults();
      final preset = widget.initialGoalId;
      if (preset != null && _type == TransactionType.goalDeposit) {
        _goalId = preset;
      }
    } else {
      _type = e.type;
      _amount = e.amount;
      _walletId = e.walletId;
      _toWalletId = e.toWalletId;
      _categoryId = e.categoryId;
      _goalId = e.goalId;
      _date = e.date;
      _note.text = e.note;
      _showNote = e.note.isNotEmpty;
    }
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

  List<Goal> _readActiveGoals() {
    final all = ref.read(goalsProvider).value ?? const <Goal>[];
    return all.where((g) => g.isActive).toList();
  }

  CategoryType get _categoryType =>
      _type == TransactionType.income ? CategoryType.income : CategoryType.expense;

  List<Category> _readCategoriesOfType() {
    final categories = ref.read(categoriesProvider).value ?? const <Category>[];
    return sortCategories(
      categories.where((c) => c.type == _categoryType).toList(),
    );
  }

  /// Dompet, kategori, dan target mengikuti transaksi terakhir dengan tipe
  /// yang sama, sehingga kasus umum cukup: ketik nominal lalu Simpan.
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

    _toWalletId = null;
    _categoryId = null;
    _goalId = null;

    switch (_type) {
      case TransactionType.transfer:
        final lastTo = last?.toWalletId;
        if (lastTo != null && ids.contains(lastTo) && lastTo != _walletId) {
          _toWalletId = lastTo;
        } else {
          _toWalletId = _firstOtherWallet(wallets, _walletId);
        }
      case TransactionType.goalDeposit:
        final goals = _readActiveGoals();
        final goalIds = goals.map((g) => g.id).toSet();
        final lastGoal = last?.goalId;
        if (lastGoal != null && goalIds.contains(lastGoal)) {
          _goalId = lastGoal;
        } else {
          _goalId = goals.isEmpty ? null : goals.first.id;
        }
      case TransactionType.income:
      case TransactionType.expense:
        final ofType = _readCategoriesOfType();
        final catIds = ofType.map((c) => c.id).toSet();
        final lastCat = last?.categoryId;
        if (lastCat != null && catIds.contains(lastCat)) {
          _categoryId = lastCat;
        } else {
          _categoryId = ofType.isEmpty ? null : ofType.first.id;
        }
    }
  }

  /// Saat mengubah tipe pada transaksi yang sudah ada: dompet dipertahankan,
  /// hanya kategori / dompet tujuan / target yang disesuaikan.
  void _adaptToType() {
    final wallets = _readActiveWallets();
    switch (_type) {
      case TransactionType.transfer:
        _categoryId = null;
        _goalId = null;
        if (_toWalletId == null || _toWalletId == _walletId) {
          _toWalletId = _firstOtherWallet(wallets, _walletId);
        }
      case TransactionType.goalDeposit:
        _categoryId = null;
        _toWalletId = null;
        final goals = _readActiveGoals();
        if (_goalId == null || !goals.any((g) => g.id == _goalId)) {
          _goalId = goals.isEmpty ? null : goals.first.id;
        }
      case TransactionType.income:
      case TransactionType.expense:
        _toWalletId = null;
        // Tautan target hanya berlaku untuk pengeluaran.
        if (_type == TransactionType.income) _goalId = null;
        if (widget.editing?.type == TransactionType.goalDeposit) _goalId = null;
        final ofType = _readCategoriesOfType();
        final catIds = ofType.map((c) => c.id).toSet();
        if (_categoryId == null || !catIds.contains(_categoryId)) {
          _categoryId = ofType.isEmpty ? null : ofType.first.id;
        }
    }
  }

  String? _firstOtherWallet(List<Wallet> wallets, String? excludeId) {
    for (final w in wallets) {
      if (w.id != excludeId) return w.id;
    }
    return null;
  }

  // ---------- Aksi ----------

  void _onTypeChanged(TransactionType type) {
    setState(() {
      _type = type;
      if (_isEditing) {
        _adaptToType();
      } else {
        _applyDefaults();
      }
    });
  }

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
      initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateChanged = true;
      });
    }
  }

  /// Batas setoran = saldo bebas (ditambah setoran lama bila sedang diubah),
  /// karena yang boleh dialokasikan hanya uang yang belum dialokasikan.
  int? get _depositLimit {
    final summary = ref.read(balanceSummaryProvider).value;
    if (summary == null) return null;
    final e = widget.editing;
    final back =
        (e != null && e.type == TransactionType.goalDeposit) ? e.amount : 0;
    return summary.freeBalance + back;
  }

  bool get _canSave {
    if (_amount <= 0 || _walletId == null) return false;
    switch (_type) {
      case TransactionType.transfer:
        return _toWalletId != null && _toWalletId != _walletId;
      case TransactionType.goalDeposit:
        final limit = _depositLimit;
        return _goalId != null && (limit == null || _amount <= limit);
      case TransactionType.income:
      case TransactionType.expense:
        return true;
    }
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

    final editing = widget.editing;
    final now = DateTime.now();
    final DateTime date;
    if (editing != null && !_dateChanged) {
      date = editing.date; // jam asli dipertahankan
    } else if (isSameDay(_date, now)) {
      date = now;
    } else {
      date = DateTime(_date.year, _date.month, _date.day, 12);
    }
    final isTransfer = _type == TransactionType.transfer;
    final isDeposit = _type == TransactionType.goalDeposit;
    final linksGoal = isDeposit || _type == TransactionType.expense;

    final tx = MoneyTransaction(
      id: editing?.id ?? repo.newId(),
      type: _type,
      amount: _amount,
      walletId: _walletId!,
      toWalletId: isTransfer ? _toWalletId : null,
      categoryId: (isTransfer || isDeposit) ? null : _categoryId,
      goalId: linksGoal ? _goalId : null,
      note: _note.text.trim(),
      date: date,
    );

    // Pengeluaran yang ditautkan ke target aktif -> tawarkan "tandai tercapai".
    Goal? offerGoal;
    if (_type == TransactionType.expense && _goalId != null) {
      for (final g in _readActiveGoals()) {
        if (g.id == _goalId) offerGoal = g;
      }
    }
    final goalRepo = ref.read(goalRepositoryProvider);

    final messenger = ScaffoldMessenger.of(context);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final label = _savedLabel;
    final amount = _amount;

    // Tidak di-await (offline-first): tampilan sudah berubah lewat stream lokal.
    if (editing == null) {
      unawaited(repo.add(tx).catchError((Object _) {}));
    } else {
      unawaited(repo.update(tx).catchError((Object _) {}));
    }

    Navigator.of(context).pop();
    messenger.hideCurrentSnackBar();
    if (editing == null) {
      messenger.showSnackBar(
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
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Perubahan tersimpan')),
      );
    }

    if (offerGoal != null && goalRepo != null) {
      unawaited(offerMarkAchieved(rootContext, goalRepo, offerGoal));
    }
  }

  Future<void> _confirmDelete() async {
    final editing = widget.editing;
    final repo = ref.read(transactionRepositoryProvider);
    if (editing == null || repo == null) return;

    final messenger = ScaffoldMessenger.of(context);
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
    if (ok != true || !mounted) return;

    unawaited(repo.delete(editing.id).catchError((Object _) {}));
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Transaksi dihapus')));
  }

  // ---------- Tampilan ----------

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final editing = widget.editing;
    final allWallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    // Dompet tersembunyi tetap tampil bila dipakai transaksi yang diubah.
    final wallets = allWallets
        .where(
          (w) =>
              w.active ||
              (editing != null &&
                  (w.id == editing.walletId || w.id == editing.toWalletId)),
        )
        .toList();
    final categories = sortCategories(
      (ref.watch(categoriesProvider).value ?? const <Category>[])
          .where((c) => c.type == _categoryType)
          .toList(),
    );
    final allGoals = ref.watch(goalsProvider).value ?? const <Goal>[];
    // Target nonaktif tetap tampil bila sedang dipakai transaksi yang diubah.
    final goals = allGoals
        .where((g) => g.isActive || g.id == editing?.goalId)
        .toList();
    ref.watch(balanceSummaryProvider); // agar batas setoran ikut diperbarui
    final isTransfer = _type == TransactionType.transfer;
    final isDeposit = _type == TransactionType.goalDeposit;
    final isExpense = _type == TransactionType.expense;

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

    Widget goalChips(ValueChanged<String> onSelect) {
      return pad(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in goals)
              ChoiceChip(
                showCheckmark: false,
                avatar: Icon(
                  iconForKey(g.iconKey),
                  size: 18,
                  color: Color(g.colorValue),
                ),
                label: Text(g.name),
                selected: _goalId == g.id,
                onSelected: (_) => onSelect(g.id),
              ),
          ],
        ),
      );
    }

    final limit = isDeposit ? _depositLimit : null;
    final overLimit = limit != null && _amount > limit;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing) ...[
              pad(
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ubah transaksi',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
              ),
              const SizedBox(height: 8),
            ],
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
                  ButtonSegment(
                    value: TransactionType.goalDeposit,
                    label: Text('Setor'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    _onTypeChanged(selection.first),
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
            label(isTransfer ? 'Dari' : (isDeposit ? 'Dari dompet' : 'Dompet')),
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
            ] else if (isDeposit) ...[
              const SizedBox(height: 12),
              label('Ke target'),
              if (goals.isEmpty)
                pad(
                  Text(
                    'Belum ada target aktif. Buat dulu di Pengaturan > Target.',
                    style: text.bodySmall?.copyWith(color: AppColors.expense),
                  ),
                )
              else
                goalChips((id) => setState(() => _goalId = id)),
              if (limit != null) ...[
                const SizedBox(height: 8),
                pad(
                  Text(
                    overLimit
                        ? 'Melebihi saldo bebas ${formatRupiah(limit)}.'
                        : 'Saldo bebas ${formatRupiah(limit)}',
                    style: text.bodySmall?.copyWith(
                      color: overLimit
                          ? AppColors.expense
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
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
              if (isExpense && goals.isNotEmpty) ...[
                const SizedBox(height: 12),
                label('Tautkan ke target (opsional)'),
                goalChips(
                  (id) => setState(() => _goalId = _goalId == id ? null : id),
                ),
              ],
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
                  child: Text(_isEditing ? 'Simpan perubahan' : 'Simpan'),
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
