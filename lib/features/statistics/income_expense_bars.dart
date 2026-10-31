import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rupiah.dart';
import '../../domain/statistics.dart';
import 'chart_common.dart';

/// Grafik batang pemasukan vs pengeluaran per minggu atau per hari dalam
/// bulan (PRD F8).
class IncomeExpenseBars extends StatelessWidget {
  const IncomeExpenseBars({
    super.key,
    required this.totals,
    required this.daily,
  });

  final List<PeriodTotals> totals;

  /// true = satu batang per hari, false = per minggu.
  final bool daily;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    var maxValue = 0;
    var totalIncome = 0;
    var totalExpense = 0;
    for (final t in totals) {
      if (t.income > maxValue) maxValue = t.income;
      if (t.expense > maxValue) maxValue = t.expense;
      totalIncome += t.income;
      totalExpense += t.expense;
    }
    if (maxValue == 0) {
      return const ChartEmpty('Belum ada pemasukan atau pengeluaran di bulan ini.');
    }

    final interval = niceInterval(maxValue);
    final maxY = (maxValue / interval).ceil() * interval;
    final axisStyle = text.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            LegendDot(color: AppColors.income, label: 'Masuk'),
            SizedBox(width: 16),
            LegendDot(color: AppColors.expense, label: 'Keluar'),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: AppColors.divider, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      formatCompactRupiah(value.toInt()),
                      maxLines: 1,
                      style: axisStyle,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= totals.length) {
                        return const SizedBox.shrink();
                      }
                      // Per hari: label tiap kelipatan 5 agar tidak berdesakan.
                      final show = !daily || i == 0 || (i + 1) % 5 == 0;
                      final label = !show ? '' : (daily ? '${i + 1}' : 'M${i + 1}');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(label, style: axisStyle),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < totals.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: [
                      BarChartRodData(
                        toY: totals[i].income.toDouble(),
                        color: AppColors.income,
                        width: daily ? 3 : 10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: totals[i].expense.toDouble(),
                        color: AppColors.expense,
                        width: daily ? 3 : 10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Total masuk ${formatRupiah(totalIncome)} · '
          'keluar ${formatRupiah(totalExpense)}',
          style: AppTheme.numeric(text.bodySmall).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (!daily)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'M1 = tanggal 1-7, M2 = 8-14, M3 = 15-21, M4 = 22-28, '
              'M5 = 29 dst.',
              style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
