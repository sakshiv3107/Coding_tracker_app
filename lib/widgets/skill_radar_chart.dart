import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'glassmorphic_container.dart';
// import '../theme/app_theme.dart';

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

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill Proficiency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 280,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.circle,
                dataSets: [
                  RadarDataSet(
                    fillColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderColor: theme.colorScheme.primary,
                    borderWidth: 3,
                    entryRadius: 4,
                    dataEntries: data.map((v) => RadarEntry(value: v)).toList(),
                  ),
                ],
                radarBorderData: const BorderSide(color: Colors.transparent),
                tickBorderData: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                gridBorderData: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), width: 1.5),
                tickCount: 5,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  return RadarChartTitle(
                    text: categories[index % categories.length],
                    angle: angle,
                  );
                },
                titlePositionPercentageOffset: 0.3,
                titleTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
