// widgets/difficulty_bar_chart.dart
// Replaces the pie chart with a clean horizontal stacked bar chart

import 'package:flutter/material.dart';
import 'modern_card.dart';

class DifficultyBarChart extends StatefulWidget {
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
  State<DifficultyBarChart> createState() => _DifficultyBarChartState();
}

class _DifficultyBarChartState extends State<DifficultyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _easyColor = Color(0xFF00C9A7);
  static const _mediumColor = Color(0xFFFFA552);
  static const _hardColor = Color(0xFFFF6B7A);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.easy + widget.medium + widget.hard;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Difficulty Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '$total solved',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stacked bar
          if (total > 0) ...[
            _buildStackedBar(total),
            const SizedBox(height: 20),
          ],

          // Individual rows
          _buildDifficultyRow('Easy', widget.easy, total, _easyColor),
          const SizedBox(height: 12),
          _buildDifficultyRow('Medium', widget.medium, total, _mediumColor),
          const SizedBox(height: 12),
          _buildDifficultyRow('Hard', widget.hard, total, _hardColor),
        ],
      ),
    );
  }

  Widget _buildStackedBar(int total) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final easyFrac = (widget.easy / total) * _animation.value;
        final medFrac = (widget.medium / total) * _animation.value;
        final hardFrac = (widget.hard / total) * _animation.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Flexible(flex: (easyFrac * 1000).round(), child: Container(color: _easyColor)),
                Flexible(flex: (medFrac * 1000).round(), child: Container(color: _mediumColor)),
                Flexible(flex: (hardFrac * 1000).round(), child: Container(color: _hardColor)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyRow(String label, int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction * _animation.value,
                minHeight: 8,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}