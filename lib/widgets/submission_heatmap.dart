import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

class SubmissionHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final Color baseColor;

  const SubmissionHeatmap({
    super.key,
    required this.datasets,
    this.baseColor = AppTheme.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // We want to show the last 52 weeks
    // Calculate the start date (Sunday of the week 51 weeks ago)
    final startDate = today.subtract(Duration(days: today.weekday % 7 + 51 * 7));
    
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submission Activity',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              _buildLegend(theme),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Show most recent first
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(52, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(Duration(days: weekIndex * 7 + dayIndex));
                      if (date.isAfter(today)) {
                        return const SizedBox(width: 12, height: 12);
                      }
                      
                      final count = datasets[DateTime(date.year, date.month, date.day)] ?? 0;
                      
                      return Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: _getColor(count, theme.brightness == Brightness.dark),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 12 months',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              Text(
                '${datasets.values.fold(0, (sum, val) => sum + val)} submissions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      children: [
        Text('Less ', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
        _legendBox(0, theme.brightness == Brightness.dark),
        _legendBox(2, theme.brightness == Brightness.dark),
        _legendBox(5, theme.brightness == Brightness.dark),
        _legendBox(8, theme.brightness == Brightness.dark),
        _legendBox(12, theme.brightness == Brightness.dark),
        Text(' More', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _legendBox(int count, bool isDark) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: _getColor(count, isDark),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getColor(int count, bool isDark) {
    if (count == 0) return isDark ? Colors.white10 : Colors.black.withOpacity(0.05);
    if (count < 3) return baseColor.withOpacity(0.25);
    if (count < 6) return baseColor.withOpacity(0.5);
    if (count < 10) return baseColor.withOpacity(0.75);
    return baseColor;
  }
}
