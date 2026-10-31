import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../data/models/enums.dart';
import '../../data/models/goal.dart';
import '../../data/providers.dart';
import '../../domain/goal_schedule.dart';
import '../transactions/quick_add_sheet.dart';
import 'goal_actions.dart';
import 'goal_card.dart';
import 'goal_form_sheet.dart';

/// Daftar Target (PRD F6): semua target aktif dan yang sudah tercapai.
/// Urutan target aktif diatur dengan menggeser (tahan ikon di kanan kartu).
/// Target yang diarsipkan ditaruh di bagian bawah agar bisa diaktifkan lagi.
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  void _reorder(WidgetRef ref, List<Goal> active, int oldIndex, int newIndex) {
    final repo = ref.read(goalRepositoryProvider);
    if (repo == null) return;
    final reordered = reorderList(active, oldIndex, newIndex);
    unawaited(repo.saveOrder(reordered).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final collected =
        ref.watch(balanceSummaryProvider).value?.goalCollected ?? const <String, int>{};

    final active =
        goals.where((g) => g.status == GoalStatus.active).toList();
    final achieved = goals
        .where((g) => g.status == GoalStatus.achieved)
        .toList()
      ..sort((a, b) {
        final da = a.achievedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.achievedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    final archived =
        goals.where((g) => g.status == GoalStatus.archived).toList();

    Widget header(String title) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Target')),
      body: goals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Belum ada target. Tap Tambah target untuk mulai.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                if (active.isNotEmpty) ...[
                  header('Aktif'),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: active.length,
                    onReorder: (o, n) => _reorder(ref, active, o, n),
                    itemBuilder: (context, i) {
                      final g = active[i];
                      return Padding(
                        key: ValueKey(g.id),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GoalCard(
                          goal: g,
                          collected: collected[g.id] ?? 0,
                          onTap: () => showGoalFormSheet(context, existing: g),
                          onDeposit: () => showQuickAddSheet(
                            context,
                            initialType: TransactionType.goalDeposit,
                            initialGoalId: g.id,
                          ),
                          onMarkAchieved: () => markGoalAchieved(ref, g),
                          trailing: active.length > 1
                              ? ReorderableDragStartListener(
                                  index: i,
                                  child: const Icon(
                                    Icons.drag_indicator_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ],
                if (achieved.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  header('Tercapai'),
                  for (final g in achieved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GoalCard(
                        goal: g,
                        collected: collected[g.id] ?? 0,
                        onTap: () => showGoalFormSheet(context, existing: g),
                      ),
                    ),
                ],
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        'Diarsipkan (${archived.length})',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      children: [
                        for (final g in archived)
                          ListTile(
                            leading: Icon(
                              iconForKey(g.iconKey),
                              color: Color(g.colorValue),
                            ),
                            title: Text(g.name),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => showGoalFormSheet(context, existing: g),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showGoalFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah target'),
      ),
    );
  }
}
