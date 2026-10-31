import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rupiah.dart';
import '../../domain/statistics.dart';
import 'chart_common.dart';

/// Grafik garis perkembangan total tabungan sepanjang bulan (PRD F8).
class SavingsLine extends StatelessWidget {
  const SavingsLine({
    super.key,
    required this.values,
    required this.month,
    required this.isCurrentMonth,
  });

  /// Total tabungan akhir hari, mulai tanggal 1.
  final List<int> values;
  final DateTime month;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const ChartEmpty('Belum ada data untuk bulan ini.');
    }
    final text = Theme.of(context).textTheme;
    final axisStyle = text.bodySmall?.copyWith(color: AppColors.textSecondary);

    var lo = values.first;
    var hi = values.first;
    for (final v in values) {
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    // Beri ruang di atas dan bawah; garis datar tetap punya rentang.
    final pad = lo == hi ? math.max(10000, hi.abs() * 0.1) : (hi - lo) * 0.15;
    var rawMin = lo - pad;
    final rawMax = hi + pad;
    if (lo >= 0 && rawMin < 0) rawMin = 0;
    final interval = niceInterval(rawMax - rawMin);
    final minY = (rawMin / interval).floor() * interval;
    final maxY = (rawMax / interval).ceil() * interval;

    final days = daysInMonth(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              minX: 1,
              maxX: days.toDouble(),
              minY: minY,
              maxY: maxY,
              lineTouchData: LineTouchData(enabled: false),
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
                    interval: 5,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${value.toInt()}', style: axisStyle),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < values.length; i++)
                      FlSpot((i + 1).toDouble(), values[i].toDouble()),
                  ],
                  isCurved: false,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(show: values.length < 3),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${isCurrentMonth ? 'Sekarang' : 'Akhir bulan'}: '
          '${formatRupiah(values.last)}',
          style: AppTheme.numeric(text.bodyMedium).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Total tabungan di akhir setiap hari (sumbu bawah = tanggal).',
          style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
