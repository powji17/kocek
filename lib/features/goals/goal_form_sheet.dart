import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/enums.dart';
import '../../data/models/goal.dart';
import '../../data/providers.dart';
import '../../shared/widgets/rupiah_field.dart';

/// Bottom sheet "Atur Target" (PRD F6 dan bagian 10). [existing] null = baru.
Future<void> showGoalFormSheet(BuildContext context, {Goal? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => GoalFormSheet(existing: existing),
  );
}

class GoalFormSheet extends ConsumerStatefulWidget {
  const GoalFormSheet({super.key, this.existing});

  final Goal? existing;

  @override
  ConsumerState<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends ConsumerState<GoalFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _target = TextEditingController(
    text: (widget.existing?.targetAmount ?? 0) == 0
        ? ''
        : formatThousands(widget.existing!.targetAmount),
  );
  late String _iconKey = widget.existing?.iconKey ?? goalIconKeys.first;
  late int _colorValue = widget.existing?.colorValue ?? goalColorPalette.first;
  late DateTime? _deadline = widget.existing?.deadline;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = _deadline ?? today.add(const Duration(days: 30));
    final first = initial.isBefore(today) ? initial : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  /// Membangun Goal dari isian, atau null (dengan pesan galat) bila tidak valid.
  Goal? _buildGoal() {
    final name = _name.text.trim();
    final target = parseRupiahInput(_target.text);
    if (name.isEmpty) {
      setState(() => _error = 'Nama target tidak boleh kosong.');
      return null;
    }
    if (target <= 0) {
      setState(() => _error = 'Isi nominal target lebih dari Rp0.');
      return null;
    }

    final existing = widget.existing;
    if (existing != null) {
      return existing.copyWith(
        name: name,
        targetAmount: target,
        iconKey: _iconKey,
        colorValue: _colorValue,
        deadline: _deadline,
        clearDeadline: _deadline == null,
      );
    }

    final repo = ref.read(goalRepositoryProvider);
    if (repo == null) return null;
    final goals = ref.read(goalsProvider).value ?? const <Goal>[];
    final nextOrder =
        goals.fold<int>(-1, (m, g) => g.order > m ? g.order : m) + 1;
    return Goal(
      id: repo.newId(),
      name: name,
      targetAmount: target,
      iconKey: _iconKey,
      colorValue: _colorValue,
      deadline: _deadline,
      order: nextOrder,
    );
  }

  void _commit(Goal goal) {
    final repo = ref.read(goalRepositoryProvider);
    if (repo == null) return;
    // Tidak di-await (offline-first).
    unawaited(repo.save(goal).catchError((Object _) {}));
    Navigator.of(context).pop();
  }

  void _save() {
    final goal = _buildGoal();
    if (goal != null) _commit(goal);
  }

  void _setStatus(GoalStatus status) {
    final goal = _buildGoal();
    if (goal == null) return;
    _commit(
      goal.copyWith(
        status: status,
        achievedAt: status == GoalStatus.achieved ? DateTime.now() : null,
        clearAchievedAt: status != GoalStatus.achieved,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existing;
    final repo = ref.read(goalRepositoryProvider);
    if (existing == null || repo == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus target "${existing.name}"?'),
        content: const Text(
          'Setoran yang sudah ada kembali menjadi saldo bebas, dan catatan '
          'setorannya ikut dihapus. Tindakan ini tidak bisa dibatalkan.',
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

    unawaited(repo.deleteWithDeposits(existing.id).catchError((Object _) {}));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final existing = widget.existing;
    final isEdit = existing != null;
    final deadline = _deadline;

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
                    isEdit ? 'Ubah target' : 'Tambah target',
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
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              decoration: const InputDecoration(labelText: 'Nama target'),
            ),
            const SizedBox(height: 12),
            RupiahField(controller: _target, label: 'Nominal target'),
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
                for (final key in goalIconKeys)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Icon(iconForKey(key), size: 20),
                    selected: _iconKey == key,
                    onSelected: (_) => setState(() => _iconKey = key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Warna',
              style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in goalColorPalette)
                  Semantics(
                    button: true,
                    selected: _colorValue == c,
                    label: 'Pilih warna',
                    child: GestureDetector(
                      onTap: () => setState(() => _colorValue = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorValue == c
                                ? AppColors.textPrimary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _colorValue == c
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Deadline (opsional)',
              style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    deadline == null
                        ? 'Tanpa deadline'
                        : formatRangeLabel(deadline, deadline),
                  ),
                  onPressed: _pickDeadline,
                ),
                if (deadline != null)
                  ActionChip(
                    avatar: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Hapus deadline'),
                    onPressed: () => setState(() => _deadline = null),
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
            if (existing != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (existing.status == GoalStatus.active) ...[
                    OutlinedButton(
                      onPressed: () => _setStatus(GoalStatus.achieved),
                      child: const Text('Tandai tercapai'),
                    ),
                    OutlinedButton(
                      onPressed: () => _setStatus(GoalStatus.archived),
                      child: const Text('Arsipkan'),
                    ),
                  ] else
                    OutlinedButton(
                      onPressed: () => _setStatus(GoalStatus.active),
                      child: const Text('Aktifkan kembali'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
