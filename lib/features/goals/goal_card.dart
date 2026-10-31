import 'dart:math' show max;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/enums.dart';
import '../../data/models/goal.dart';
import '../../domain/goal_schedule.dart';

/// Kartu target: nama, progres (bar dan persentase), sisa nominal, dan
/// rencana deadline (PRD F4 dan F6).
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.collected,
    this.onTap,
    this.onDeposit,
    this.onMarkAchieved,
    this.trailing,
  });

  final Goal goal;
  final int collected;
  final VoidCallback? onTap;

  /// Tombol "Setor" (hanya untuk target aktif).
  final VoidCallback? onDeposit;

  /// Tombol "Tandai tercapai" (muncul saat progres 100%).
  final VoidCallback? onMarkAchieved;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final target = goal.targetAmount;
    final progress = target <= 0 ? 0.0 : (collected / target).clamp(0.0, 1.0);
    // 99,6% tidak boleh tampil sebagai 100%.
    final percent = progress >= 1 ? 100 : (progress * 100).floor();
    final remaining = max(0, target - collected);
    final accent = Color(goal.colorValue);
    final isActive = goal.status == GoalStatus.active;
    final deadline = goal.deadline;
    final schedule = isActive
        ? scheduleFor(remaining: remaining, deadline: deadline, now: DateTime.now())
        : null;

    final String statusText;
    switch (goal.status) {
      case GoalStatus.active:
        statusText = progress >= 1
            ? 'Target tercapai, selamat!'
            : 'Sisa ${formatRupiah(remaining)} lagi, semangat!';
      case GoalStatus.achieved:
        final at = goal.achievedAt;
        statusText =
            at == null ? 'Tercapai' : 'Tercapai pada ${formatRangeLabel(at, at)}';
      case GoalStatus.archived:
        statusText = 'Diarsipkan';
    }

    final lines = <Widget>[];
    if (schedule != null && deadline != null) {
      final dateText = formatRangeLabel(deadline, deadline);
      if (schedule.isOverdue && remaining > 0) {
        lines.add(
          Text(
            'Lewat ${-schedule.daysLeft} hari dari deadline ($dateText)',
            style: text.bodySmall?.copyWith(color: AppColors.expense),
          ),
        );
      } else if (remaining > 0) {
        lines.add(
          Text(
            schedule.daysLeft == 0
                ? 'Deadline hari ini ($dateText)'
                : 'Sisa ${schedule.daysLeft} hari ($dateText)',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        );
        if (schedule.perWeek != null && schedule.perMonth != null) {
          lines.add(
            Text(
              'Perlu sekitar ${formatRupiah(schedule.perWeek!)}/minggu atau '
              '${formatRupiah(schedule.perMonth!)}/bulan',
              style: AppTheme.numeric(text.bodySmall)
                  .copyWith(color: AppColors.textSecondary),
            ),
          );
        }
      }
    }

    final showMark = isActive && progress >= 1 && onMarkAchieved != null;
    final showDeposit = isActive && onDeposit != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconForKey(goal.iconKey), size: 22, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: AppTheme.numeric(text.titleMedium).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Bar progres terisi dengan animasi singkat (PRD bagian 14).
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    color: accent,
                    backgroundColor: AppColors.divider,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Terkumpul ${formatRupiah(collected)} dari ${formatRupiah(target)}',
                style: AppTheme.numeric(text.bodyMedium).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: AppTheme.numeric(text.bodyMedium).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final line in lines) ...[
                const SizedBox(height: 2),
                line,
              ],
              if (showDeposit || showMark) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (showDeposit)
                      OutlinedButton.icon(
                        onPressed: onDeposit,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Setor'),
                      ),
                    if (showMark)
                      FilledButton(
                        onPressed: onMarkAchieved,
                        child: const Text('Tandai tercapai'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
