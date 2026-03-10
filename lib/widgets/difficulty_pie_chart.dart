import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';
import 'animations/animated_stat_counter.dart';

class DifficultyBarChart extends StatelessWidget {
  final int easy;
  final int medium;
  final int hard;

  const DifficultyBarChart({
    super.key,
    required this.easy,
    required this.medium,
    required this.hard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = easy + medium + hard;
    
    // Fallback if total is 0 to avoid division by zero
    final safeTotal = total > 0 ? total : 1;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solving Difficulty',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              AnimatedStatCounter(
                value: total,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ) ?? const TextStyle(),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Stacked Bar Chart
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 16,
              width: double.infinity,
              child: Row(
                children: [
                  if (easy > 0)
                    Expanded(
                      flex: (easy / safeTotal * 100).toInt(),
                      child: Container(color: AppTheme.secondary),
                    ),
                  if (medium > 0)
                    Expanded(
                      flex: (medium / safeTotal * 100).toInt(),
                      child: Container(color: Colors.amber),
                    ),
                  if (hard > 0)
                    Expanded(
                      flex: (hard / safeTotal * 100).toInt(),
                      child: Container(color: Colors.redAccent),
                    ),
                  if (total == 0)
                    Expanded(
                      child: Container(color: theme.colorScheme.surfaceContainerHighest),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Legend
          Row(
            children: [
              Expanded(child: _buildLegendItem('Easy', easy, safeTotal, AppTheme.secondary)),
              Expanded(child: _buildLegendItem('Medium', medium, safeTotal, Colors.amber)),
              Expanded(child: _buildLegendItem('Hard', hard, safeTotal, Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedStatCounter(
                value: count,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 4),
              Text(
                '(${((count / total) * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
