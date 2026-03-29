import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class MonthlyProgressChart extends StatelessWidget {
  final Map<DateTime, int> submissionCalendar;

  const MonthlyProgressChart({super.key, required this.submissionCalendar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  //  final isDark = theme.brightness == Brightness.dark;

    // Aggregate monthly data for the last 6 months
    final Map<int, int> monthlyData = {};
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
       final monthDate = DateTime(now.year, now.month - i, 1);
       monthlyData[monthDate.month] = 0;
    }

    submissionCalendar.forEach((date, count) {
      // final monthStart = DateTime(date.year, date.month, 1);
      if (monthlyData.containsKey(date.month)) {
        monthlyData[date.month] = (monthlyData[date.month] ?? 0) + count;
      }
    });

    final sortedMonths = monthlyData.keys.toList()..sort();
    final List<BarChartGroupData> groups = [];
    int maxVal = 0;

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final val = monthlyData[month] ?? 0;
      if (val > maxVal) maxVal = val;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val.toDouble(),
              color: AppTheme.primary,
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: (maxVal * 1.2).clamp(10, 1000).toDouble(),
                color: theme.colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
          ],
        ),
      );
    }

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Progress',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVal * 1.2).clamp(10, 1000).toDouble(),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedMonths.length) return const SizedBox();
                        final monthNum = sortedMonths[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('MMM').format(DateTime(2024, monthNum)),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
