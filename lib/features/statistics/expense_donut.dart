import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/category.dart';
import '../../domain/statistics.dart';
import 'chart_common.dart';

/// Grafik donat komposisi pengeluaran per kategori, lengkap dengan persen
/// dan nominal (PRD F8).
class ExpenseDonut extends StatelessWidget {
  const ExpenseDonut({
    super.key,
    required this.slices,
    required this.categories,
  });

  final List<CategorySlice> slices;
  final Map<String, Category> categories;

  static const Color _noCategory = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const ChartEmpty('Belum ada pengeluaran di bulan ini.');
    }
    final text = Theme.of(context).textTheme;
    final total = slices.fold<int>(0, (sum, s) => sum + s.amount);

    Color colorOf(CategorySlice s) {
      final c = categories[s.categoryId];
      return c == null ? _noCategory : Color(c.colorValue);
    }

    return Column(
      children: [
        SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 66,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(enabled: false),
                  sections: [
                    for (final s in slices)
                      PieChartSectionData(
                        value: s.amount.toDouble(),
                        color: colorOf(s),
                        radius: 30,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total keluar',
                    style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRupiah(total),
                    style: AppTheme.numeric(text.titleMedium).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorOf(s),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categories[s.categoryId]?.name ?? 'Tanpa kategori',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatPercent(s.amount, total),
                  style: AppTheme.numeric(text.bodyMedium).copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatRupiah(s.amount),
                  style: AppTheme.numeric(text.bodyMedium).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
