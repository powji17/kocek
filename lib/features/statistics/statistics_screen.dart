import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/category.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../../domain/statistics.dart';
import 'expense_donut.dart';
import 'income_expense_bars.dart';
import 'savings_line.dart';

/// Statistik (PRD F8): pilih bulan, insight, grafik donat per kategori,
/// grafik batang pemasukan vs pengeluaran, dan grafik garis total tabungan.
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _daily = false;

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final transactions =
        ref.watch(transactionsProvider).value ?? const <MoneyTransaction>[];
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];

    final categoryMap = {for (final c in categories) c.id: c};
    final slices = expenseByCategory(transactions, _month);
    final insight = buildInsight(
      slices: slices,
      categoryNames: {for (final c in categories) c.id: c.name},
      month: _month,
      now: now,
    );
    final totals = _daily
        ? dailyTotals(transactions, _month)
        : weeklyTotals(transactions, _month);
    final series = savingsSeries(
      wallets: wallets,
      transactions: transactions,
      month: _month,
      now: now,
    );
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    Widget section(String title, Widget child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Pengatur bulan: sebelumnya / berikutnya.
        Row(
          children: [
            IconButton(
              tooltip: 'Bulan sebelumnya',
              onPressed: () => _shift(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: Text(
                  formatMonthYear(_month),
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              onPressed: _canGoNext ? () => _shift(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Insight otomatis: satu kalimat.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: text.bodyMedium?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        section(
          'Pengeluaran per kategori',
          ExpenseDonut(slices: slices, categories: categoryMap),
        ),
        const SizedBox(height: 24),
        section(
          'Pemasukan vs pengeluaran',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                segments: const [
                  ButtonSegment(value: false, label: Text('Per minggu')),
                  ButtonSegment(value: true, label: Text('Per hari')),
                ],
                selected: {_daily},
                onSelectionChanged: (s) => setState(() => _daily = s.first),
              ),
              const SizedBox(height: 16),
              IncomeExpenseBars(totals: totals, daily: _daily),
            ],
          ),
        ),
        const SizedBox(height: 24),
        section(
          'Perkembangan tabungan',
          SavingsLine(
            values: series,
            month: _month,
            isCurrentMonth: isCurrentMonth,
          ),
        ),
      ],
    );
  }
}
