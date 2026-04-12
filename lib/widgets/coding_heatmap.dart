import 'package:flutter/material.dart';
import 'activity_heatmap.dart';
import 'modern_card.dart';
// import '../theme/app_theme.dart';

class CodingHeatmap extends StatelessWidget {
  final Map<DateTime, int> datasets;

  const CodingHeatmap({super.key, required this.datasets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      isGlass: true,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Coding Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Last 12 Months',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ActivityHeatmap(
            data: datasets,
            baseColor: theme.colorScheme.primary,
            label: '',
            tooltipLabel: 'activities',
            showStats: false,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/activity_heatmap'),
              icon: Icon(Icons.analytics_rounded, size: 16, color: theme.colorScheme.primary),
              label: Text(
                'Explore Detailed Activity Report',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
