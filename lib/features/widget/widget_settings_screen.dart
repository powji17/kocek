import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/icon_keys.dart';
import '../../data/models/goal.dart';
import '../../data/providers.dart';
import '../../domain/widget_snapshot.dart';
import 'widget_providers.dart';
import 'widget_service.dart';

/// Pengaturan widget homescreen (PRD F9): pilih satu target yang ditampilkan
/// dan opsi sembunyikan nominal.
class WidgetSettingsScreen extends ConsumerWidget {
  const WidgetSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final settings = ref.watch(widgetSettingsProvider).value ?? const WidgetSettings();
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final summary = ref.watch(balanceSummaryProvider).value;
    final activeGoals = goals.where((g) => g.isActive).toList();
    final snapshot = buildWidgetSnapshot(
      summary: summary,
      goals: goals,
      settings: settings,
      now: DateTime.now(),
    );
    final notifier = ref.read(widgetSettingsProvider.notifier);

    Widget header(String title) => Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    Widget option({
      required String title,
      required String? value,
      IconData? icon,
      Color? iconColor,
    }) {
      final selected = settings.goalId == value;
      return ListTile(
        leading: icon == null ? null : Icon(icon, color: iconColor),
        title: Text(title),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: AppColors.primary)
            : null,
        onTap: () => notifier.setGoal(value),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Widget homescreen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cara memasang: tekan lama layar utama HP, pilih Widget, '
                    'lalu cari Kocek dan tarik ke layar utama.',
                    style: text.bodyMedium?.copyWith(color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          header('Pratinjau'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total tabungan',
                    style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    snapshot.totalText,
                    style: AppTheme.numeric(text.headlineSmall).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (snapshot.goalVisible) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.goalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${snapshot.goalPercent}%',
                          style: AppTheme.numeric(text.titleSmall).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: snapshot.goalPercent / 100,
                        minHeight: 8,
                        color: AppColors.goal,
                        backgroundColor: AppColors.divider,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      snapshot.goalDetail,
                      style: AppTheme.numeric(text.bodySmall).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    snapshot.updatedText,
                    style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          header('Privasi'),
          Card(
            child: SwitchListTile(
              title: const Text('Sembunyikan nominal'),
              subtitle: const Text('Saldo dan nominal target tampil sebagai Rp•••••'),
              value: settings.hideAmounts,
              onChanged: notifier.setHideAmounts,
            ),
          ),
          const SizedBox(height: 24),
          header('Target yang ditampilkan'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                option(title: 'Target aktif pertama (otomatis)', value: null),
                for (final g in activeGoals) ...[
                  const Divider(),
                  option(
                    title: g.name,
                    value: g.id,
                    icon: iconForKey(g.iconKey),
                    iconColor: Color(g.colorValue),
                  ),
                ],
                const Divider(),
                option(title: 'Tanpa target', value: kWidgetGoalNone),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await pushWidgetSnapshot(snapshot);
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Widget diperbarui')));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Perbarui widget sekarang'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Widget diperbarui otomatis setiap ada perubahan dan saat Kocek '
            'dibuka. Waktu pembaruan terakhir tertera di widget.',
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
