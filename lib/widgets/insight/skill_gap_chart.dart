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

  // LeetCode GraphQL returns singular/variant names — map display → possible API keys
  static const _topicAliases = <String, List<String>>{
    'Arrays':            ['Array', 'Arrays'],
    'Strings':           ['String', 'Strings'],
    'Trees':             ['Tree', 'Binary Tree', 'Trees'],
    'Graphs':            ['Graph', 'Graphs', 'Graph Theory'],
    'Dynamic Programming': ['Dynamic Programming'],
    'Greedy':            ['Greedy'],
    'Backtracking':      ['Backtracking'],
    'Segment Tree':      ['Segment Tree'],
    'Bit Manipulation':  ['Bit Manipulation'],
    'Math':              ['Math', 'Mathematics'],
  };

  // Max solved count considered "mastered" per topic
  static const _thresholds = <String, int>{
    'Arrays':            50,
    'Strings':           40,
    'Trees':             35,
    'Graphs':            30,
    'Dynamic Programming': 40,
    'Greedy':            40,
    'Backtracking':      20,
    'Segment Tree':      15,
    'Bit Manipulation':  20,
    'Math':              30,
  };

  int _resolve(String displayName) {
    final aliases = _topicAliases[displayName] ?? [displayName];
    int total = 0;
    for (final key in aliases) {
      // Case-insensitive fuzzy lookup
      for (final entry in tagStats.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) {
          total += entry.value;
        }
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
      return _TopicScore(displayName, solved, percentage);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Topic Proficiency',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: 20),
          ...topicData.map((data) => _buildBar(context, data)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, delay: 100.ms);
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(Colors.green, '≥70%'),
        const SizedBox(width: 8),
        _legendDot(Colors.amber, '40–69%'),
        const SizedBox(width: 8),
        _legendDot(Colors.red, '<40%'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildBar(BuildContext context, _TopicScore data) {
    final theme = Theme.of(context);

    final Color color;
    if (data.percentage >= 70) {
      color = Colors.green;
    } else if (data.percentage >= 40) {
      color = Colors.amber;
    } else {
      color = Colors.red;
    }

    final maxBarWidth = MediaQuery.of(context).size.width - 80;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => onTapTopic(data.name),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${data.solved} solved (${data.percentage.toInt()}%)',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              children: [
                Container(
                  height: 7,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  height: 7,
                  width: maxBarWidth * (data.percentage / 100),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.25),
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
    );
  }
}

class _TopicScore {
  final String name;
  final int solved;
  final double percentage;

  _TopicScore(this.name, this.solved, this.percentage);
}
