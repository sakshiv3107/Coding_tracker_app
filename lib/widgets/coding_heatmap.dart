import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class CodingHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;

  const CodingHeatmap({super.key, required this.datasets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coding Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Last 12 Months',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          HeatMap(
            datasets: datasets,
            colorMode: ColorMode.opacity,
            showText: false,
            scrollable: true,
            size: 18,
            borderRadius: 4,
            startDate: DateTime.now().subtract(const Duration(days: 365)),
            endDate: DateTime.now(),
            colorsets: {
              1: AppTheme.primary.withOpacity(0.2),
              2: AppTheme.primary.withOpacity(0.4),
              3: AppTheme.primary.withOpacity(0.6),
              4: AppTheme.primary.withOpacity(0.8),
              5: AppTheme.primary,
            },
            onClick: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(value.toString())),
              );
            },
          ),
        ],
      ),
    );
  }
}
