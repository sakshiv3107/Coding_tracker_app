// lib/widgets/insight/skill_gap_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SkillGapChart extends StatelessWidget {
  final Map<String, int> tagStats;
  final Function(String topic) onTapTopic;

  const SkillGapChart({
    super.key,
    required this.tagStats,
    required this.onTapTopic,
  });

  static const _topicAliases = <String, List<String>>{
    'Arrays':              ['Array', 'Arrays'],
    'Strings':             ['String', 'Strings'],
    'Trees':               ['Tree', 'Binary Tree', 'Trees'],
    'Graphs':              ['Graph', 'Graphs', 'Graph Theory'],
    'Dynamic Programming': ['Dynamic Programming'],
    'Greedy':              ['Greedy'],
    'Backtracking':        ['Backtracking'],
    'Segment Tree':        ['Segment Tree'],
    'Bit Manipulation':    ['Bit Manipulation'],
    'Math':                ['Math', 'Mathematics'],
  };

  static const _thresholds = <String, int>{
    'Arrays': 50, 'Strings': 40, 'Trees': 35, 'Graphs': 30,
    'Dynamic Programming': 40, 'Greedy': 40, 'Backtracking': 20,
    'Segment Tree': 15, 'Bit Manipulation': 20, 'Math': 30,
  };

  // Topic category for icon selection
  static const _topicIcons = <String, IconData>{
    'Arrays': Icons.view_array_rounded,
    'Strings': Icons.text_fields_rounded,
    'Trees': Icons.account_tree_rounded,
    'Graphs': Icons.hub_rounded,
    'Dynamic Programming': Icons.layers_rounded,
    'Greedy': Icons.bolt_rounded,
    'Backtracking': Icons.undo_rounded,
    'Segment Tree': Icons.segment_rounded,
    'Bit Manipulation': Icons.memory_rounded,
    'Math': Icons.calculate_rounded,
  };

  int _resolve(String displayName) {
    final aliases = _topicAliases[displayName] ?? [displayName];
    int total = 0;
    for (final key in aliases) {
      for (final entry in tagStats.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) total += entry.value;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final topicData = _topicAliases.keys.map((displayName) {
      final solved = _resolve(displayName);
      final threshold = _thresholds[displayName] ?? 40;
      final percentage = (solved / threshold * 100).clamp(0.0, 100.0);
      return _TopicScore(displayName, solved, threshold, percentage);
    }).toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage)); // weakest first

    final hasData = topicData.any((t) => t.solved > 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.radar_rounded, size: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skill Gap Analysis',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Sorted by weakest first',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasData)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, 
                        size: 36, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                    const SizedBox(height: 10),
                    Text(
                      'No topic data yet.\nSolve problems to see your skill gaps.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...topicData.asMap().entries.map((entry) =>
              _buildBar(context, entry.value, entry.key * 80).animate().fadeIn(
                delay: Duration(milliseconds: entry.key * 60),
              ).slideX(begin: -0.05),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, delay: 100.ms);
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendRow(Colors.red.shade400, 'Gap'),
        const SizedBox(height: 2),
        _legendRow(Colors.amber, 'Growing'),
        const SizedBox(height: 2),
        _legendRow(Colors.green, 'Strong'),
      ],
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 3, 
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildBar(BuildContext context, _TopicScore data, int delayMs) {
    final theme = Theme.of(context);

    Color barColor;
    String masteryLabel;
    if (data.percentage >= 80) {
      barColor = Colors.green;
      masteryLabel = 'Expert';
    } else if (data.percentage >= 55) {
      barColor = Colors.lightGreen;
      masteryLabel = 'Proficient';
    } else if (data.percentage >= 30) {
      barColor = Colors.amber;
      masteryLabel = 'Developing';
    } else {
      barColor = Colors.red.shade400;
      masteryLabel = 'Novice';
    }

    final icon = _topicIcons[data.name] ?? Icons.code_rounded;
    final maxBarWidth = MediaQuery.of(context).size.width - 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => onTapTopic(data.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Topic Icon
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: barColor),
              ),
              const SizedBox(width: 12),
              // Bar and labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: barColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                masteryLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: barColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${data.solved}/${data.threshold}',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Stack(
                      children: [
                        // Background track
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Progress fill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          height: 6,
                          width: maxBarWidth * (data.percentage / 100),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [barColor.withOpacity(0.6), barColor],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: barColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicScore {
  final String name;
  final int solved;
  final int threshold;
  final double percentage;

  _TopicScore(this.name, this.solved, this.threshold, this.percentage);
}
