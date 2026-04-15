import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weekly_activity.dart';
import 'glass_card.dart';
import 'responsive_row.dart';

class WeeklyActivityChart extends StatefulWidget {
  final Map<DateTime, int> leetcodeCalendar;
  final Map<DateTime, int> githubCalendar;
  final Map<DateTime, int>? hackerrankCalendar;
  final Map<DateTime, int>? codechefCalendar;

  const WeeklyActivityChart({
    super.key,
    required this.leetcodeCalendar,
    required this.githubCalendar,
    this.hackerrankCalendar,
    this.codechefCalendar,
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
  static const _codechefColor = Color.fromARGB(255, 45, 188, 224);

  @override
  void initState() {
    super.initState();
    _weeklyActivity = WeeklyActivity.fromData(
      leetcodeCalendar: widget.leetcodeCalendar,
      githubCalendar: widget.githubCalendar,
      hackerrankCalendar: widget.hackerrankCalendar ?? {},
      codechefCalendar: widget.codechefCalendar ?? {},
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
        widget.hackerrankCalendar != oldWidget.hackerrankCalendar ||
        widget.codechefCalendar != oldWidget.codechefCalendar) {
      setState(() {
        _weeklyActivity = WeeklyActivity.fromData(
          leetcodeCalendar: widget.leetcodeCalendar,
          githubCalendar: widget.githubCalendar,
          hackerrankCalendar: widget.hackerrankCalendar ?? {},
          codechefCalendar: widget.codechefCalendar ?? {},
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



  @override
  Widget build(BuildContext context) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = _weeklyActivity.maxActivity.toDouble().clamp(1.0, double.infinity);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveRow(
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Evolution Stream',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (_weeklyActivity.isDummyData) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DEMO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot('LC', _leetcodeColor),
                  const SizedBox(width: 12),
                  _buildLegendDot('GH', _githubColor),
                  const SizedBox(width: 12),
                  _buildLegendDot('HR', _hackerrankColor),
                  const SizedBox(width: 12),
                  _buildLegendDot('CC', _codechefColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) => BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal * 1.3,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      tooltipBorderRadius: BorderRadius.circular(12),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = _weeklyActivity.days[groupIndex];
                        String label = '';
                        int val = 0;
                        if (rodIndex == 0) { label = 'LC'; val = day.leetcodeSubmissions; }
                        else if (rodIndex == 1) { label = 'GH'; val = day.githubCommits; }
                        else if (rodIndex == 2) { label = 'HR'; val = day.hackerrankSubmissions; }
                        else { label = 'CC'; val = day.codechefSubmissions; }
                        return BarTooltipItem(
                          '$label: $val',
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
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
                          const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                          final index = value.toInt() % 7;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              days[index],
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
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
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    final day = _weeklyActivity.days[i];
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        _buildRod(day.leetcodeSubmissions.toDouble(), _leetcodeColor),
                        _buildRod(day.githubCommits.toDouble(), _githubColor),
                        _buildRod(day.hackerrankSubmissions.toDouble(), _hackerrankColor),
                        _buildRod(day.codechefSubmissions.toDouble(), _codechefColor),
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

  BarChartRodData _buildRod(double value, Color color) {
    return BarChartRodData(
      toY: value * _animation.value,
      color: color,
      width: 7,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: 0,
        color: color.withOpacity(0.05),
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


