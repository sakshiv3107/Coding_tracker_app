import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weekly_activity.dart';
import 'modern_card.dart';
import 'responsive_row.dart';

class WeeklyActivityChart extends StatefulWidget {
  final Map<DateTime, int> leetcodeCalendar;
  final Map<DateTime, int> githubCalendar;
  final Map<DateTime, int>? hackerrankCalendar;

  const WeeklyActivityChart({
    super.key,
    required this.leetcodeCalendar,
    required this.githubCalendar,
    this.hackerrankCalendar,
  });

  @override
  State<WeeklyActivityChart> createState() => _WeeklyActivityChartState();
}

class _WeeklyActivityChartState extends State<WeeklyActivityChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WeeklyActivity _weeklyActivity;

  static const _leetcodeColor = Color(0xFFFFA116); // LeetCode yellow
  static const _githubColor = Color(0xFF6C63FF);
  static const _hackerrankColor = Color(0xFF2EC866);

  @override
  void initState() {
    super.initState();
    _weeklyActivity = WeeklyActivity.fromData(
      leetcodeCalendar: widget.leetcodeCalendar,
      githubCalendar: widget.githubCalendar,
      hackerrankCalendar: widget.hackerrankCalendar ?? {},
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(WeeklyActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.leetcodeCalendar != oldWidget.leetcodeCalendar ||
        widget.githubCalendar != oldWidget.githubCalendar ||
        widget.hackerrankCalendar != oldWidget.hackerrankCalendar) {
      setState(() {
        _weeklyActivity = WeeklyActivity.fromData(
          leetcodeCalendar: widget.leetcodeCalendar,
          githubCalendar: widget.githubCalendar,
          hackerrankCalendar: widget.hackerrankCalendar ?? {},
        );
      });
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = _weeklyActivity.maxActivity.toDouble().clamp(1.0, double.infinity);

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveRow(
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This Week',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_weeklyActivity.isDummyData) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('SAMPLE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot('LC', _leetcodeColor),
                  const SizedBox(width: 8),
                  _buildLegendDot('GH', _githubColor),
                  const SizedBox(width: 8),
                  _buildLegendDot('HR', _hackerrankColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) => BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.3,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 10,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = _weeklyActivity.days[groupIndex];
                        String label = '';
                        int val = 0;
                        if (rodIndex == 0) {
                          label = 'LC';
                          val = day.leetcodeSubmissions;
                        } else if (rodIndex == 1) {
                          label = 'GH';
                          val = day.githubCommits;
                        } else {
                          label = 'HR';
                          val = day.hackerrankSubmissions;
                        }
                        return BarTooltipItem(
                          '$label: $val',
                          const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= _dayLabels.length) return const SizedBox();
                          return Text(
                            _dayLabels[value.toInt()],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final day = _weeklyActivity.days[i];
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: day.leetcodeSubmissions * _animation.value,
                          color: _leetcodeColor,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: day.githubCommits * _animation.value,
                          color: _githubColor,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: day.hackerrankSubmissions * _animation.value,
                          color: _hackerrankColor,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}