import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/category.dart';
import '../../data/models/goal.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../../domain/balances.dart';
import '../../domain/monthly_summary.dart';
import '../../shared/widgets/transaction_tile.dart';
import '../shell/shell_providers.dart';

/// Beranda (PRD F4): saldo, dompet, target, ringkasan bulan ini, dan
/// transaksi terbaru, semuanya memakai data asli.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(balanceSummaryProvider);
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final goals = ref.watch(goalsProvider).value ?? const <Goal>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final transactions =
        ref.watch(transactionsProvider).value ?? const <MoneyTransaction>[];

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Gagal memuat data.\n$error'),
        ),
      ),
      data: (summary) => _HomeContent(
        summary: summary,
        wallets: wallets,
        goals: goals,
        categories: categories,
        transactions: transactions,
        onSeeAll: () => ref.read(selectedTabProvider.notifier).select(1),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.summary,
    required this.wallets,
    required this.goals,
    required this.categories,
    required this.transactions,
    required this.onSeeAll,
  });

  final BalanceSummary summary;
  final List<Wallet> wallets;
  final List<Goal> goals;
  final List<Category> categories;

  /// Terbaru di atas.
  final List<MoneyTransaction> transactions;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final activeWallets = wallets.where((w) => w.active).toList();
    final activeGoals = goals.where((g) => g.isActive).toList();

    return ListView(
      // Padding bawah ekstra supaya konten tidak tertutup tombol +.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        _BalanceCard(
          total: summary.totalSavings,
          freeBalance: summary.freeBalance,
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Dompet'),
        const SizedBox(height: 12),
        if (activeWallets.isEmpty)
          Text(
            'Belum ada dompet aktif. Atur di Pengaturan > Kelola dompet.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final w in activeWallets)
                    SizedBox(
                      width: tileWidth,
                      child: _WalletTile(
                        wallet: w,
                        balance: summary.walletBalances[w.id] ?? 0,
                      ),
                    ),
                ],
              );
            },
          ),
        if (activeGoals.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionTitle('Target'),
          const SizedBox(height: 12),
          for (final g in activeGoals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(
                goal: g,
                collected: summary.goalCollected[g.id] ?? 0,
              ),
            ),
        ],
        const SizedBox(height: 24),
        _MonthlySummarySection(
          summary: MonthlySummary.compute(transactions, DateTime.now()),
          month: DateTime.now(),
        ),
        const SizedBox(height: 24),
        _RecentTransactions(
          transactions: transactions,
          categories: categories,
          wallets: wallets,
          goals: goals,
          onSeeAll: onSeeAll,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.total, required this.freeBalance});

  final int total;

  /// Total tabungan dikurangi uang yang sudah dialokasikan ke target (F4 #1).
  final int freeBalance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total tabungan',
            style: text.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          // Angka saldo = bintang utama layar (bold + tabular figures).
          Text(
            formatRupiah(total),
            style: AppTheme.numeric(text.headlineLarge).copyWith(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Saldo bebas ${formatRupiah(freeBalance)}',
              style: AppTheme.numeric(text.labelLarge).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({required this.wallet, required this.balance});

  final Wallet wallet;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconForKey(wallet.iconKey),
                size: 22,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              wallet.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              formatRupiah(balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.numeric(text.titleMedium).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.collected});

  final Goal goal;
  final int collected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final target = goal.targetAmount;
    final progress = target <= 0 ? 0.0 : (collected / target).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final remaining = max(0, target - collected);
    final accent = Color(goal.colorValue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              progress >= 1
                  ? 'Target tercapai, selamat!'
                  : 'Sisa ${formatRupiah(remaining)} lagi, semangat!',
              style: AppTheme.numeric(text.bodyMedium).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _MonthlySummarySection extends StatelessWidget {
  const _MonthlySummarySection({required this.summary, required this.month});

  final MonthlySummary summary;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('Ringkasan bulan ini')),
            Text(
              formatMonthYear(month),
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Masuk',
                    value: formatRupiah(summary.income),
                    color: AppColors.income,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Keluar',
                    value: formatRupiah(summary.expense),
                    color: AppColors.expense,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: 'Selisih',
                    value: formatRupiah(summary.net, withSign: true),
                    color: summary.net < 0
                        ? AppColors.expense
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: AppTheme.numeric(text.titleSmall).copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({
    required this.transactions,
    required this.categories,
    required this.wallets,
    required this.goals,
    required this.onSeeAll,
  });

  final List<MoneyTransaction> transactions;
  final List<Category> categories;
  final List<Wallet> wallets;
  final List<Goal> goals;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final recent = transactions.take(5).toList();
    final categoryMap = {for (final c in categories) c.id: c};
    final walletMap = {for (final w in wallets) w.id: w};
    final goalMap = {for (final g in goals) g.id: g};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('Transaksi terbaru')),
            if (recent.isNotEmpty)
              TextButton(onPressed: onSeeAll, child: const Text('Lihat semua')),
          ],
        ),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Belum ada transaksi. Tap Catat untuk mulai.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(),
                  TransactionTile(
                    transaction: recent[i],
                    categories: categoryMap,
                    wallets: walletMap,
                    goals: goalMap,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
