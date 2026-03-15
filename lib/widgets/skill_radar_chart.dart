import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class SkillRadarChart extends StatelessWidget {
  final Map<String, int> tagStats;

  const SkillRadarChart({super.key, required this.tagStats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const categories = [
      'Array',
      'String',
      'Hash Table',
      'Dynamic Programming',
      'Tree',
      'Graph',
    ];

    final data = categories.map((cat) {
      double value = (tagStats[cat] ?? 0).toDouble();
      // Normalize or cap for the chart
      return value > 20 ? 20.0 : value;
    }).toList();

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill Proficiency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.circle,
                dataSets: [
                  RadarDataSet(
                    fillColor: AppTheme.primary.withOpacity(0.2),
                    borderColor: AppTheme.primary,
                    entryRadius: 3,
                    dataEntries: data.map((v) => RadarEntry(value: v)).toList(),
                  ),
                ],
                radarBorderData: const BorderSide(color: Colors.transparent),
                tickBorderData: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                gridBorderData: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: categories[index],
                    angle: angle,
                  );
                },
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
