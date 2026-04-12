import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rating_point.dart';
import 'package:intl/intl.dart';

class PlatformDonutChart extends StatefulWidget {
  final Map<String, int> platformSolvedCounts;

  const PlatformDonutChart({super.key, required this.platformSolvedCounts});

  @override
  State<PlatformDonutChart> createState() => _PlatformDonutChartState();
}

class _PlatformDonutChartState extends State<PlatformDonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToPlatform(String platform) {
    final route = '/${platform.toLowerCase()}_stats';
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = widget.platformSolvedCounts.entries.where((e) => e.value > 0).toList();
    if (filteredData.isEmpty) return const SizedBox.shrink();

    final total = filteredData.fold<int>(0, (sum, e) => sum + e.value);

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        
                        if (event is FlTapUpEvent) {
                          final platform = filteredData[_touchedIndex].key;
                          _navigateToPlatform(platform);
                        }
                      });
                    },
                  ),
                  startDegreeOffset: 270,
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: List.generate(filteredData.length, (i) {
                    final e = filteredData[i];
                    final isTouched = i == _touchedIndex;
                    final radius = isTouched ? 30.0 : 20.0;
                    
                    return PieChartSectionData(
                      color: _getPlatformColor(e.key),
                      value: e.value.toDouble() * _animation.value,
                      title: isTouched ? e.key : '',
                      radius: radius,
                      titleStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _touchedIndex == -1 ? "Total Solved" : filteredData[_touchedIndex].key,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                _touchedIndex == -1 ? total.toString() : filteredData[_touchedIndex].value.toString(),
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              if (_touchedIndex != -1)
                Text(
                  "Tap to view detail",
                  style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF7B68EE)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode': return const Color(0xFFEF9F27);
      case 'codechef': return const Color(0xFF7B68EE);
      case 'github': return const Color(0xFF4078c0);
      case 'codeforces': return const Color(0xFFE24B4A);
      case 'hackerrank': return const Color(0xFF2EC866);
      default: return Colors.grey;
    }
  }
}

class RatingHistoryChart extends StatelessWidget {
  final Map<String, List<RatingPoint>> history;

  const RatingHistoryChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rating Trends",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM').format(date),
                            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: history.entries.map((entry) {
                  final points = entry.value;
                  if (points.isEmpty) return LineChartBarData(show: false);
                  
                  return LineChartBarData(
                    spots: points.map((p) => FlSpot(p.date.millisecondsSinceEpoch.toDouble(), p.rating.toDouble())).toList(),
                    isCurved: true,
                    color: _getPlatformColor(entry.key),
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        if (index == barData.spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: _getPlatformColor(entry.key),
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 0);
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  );
                }).toList(),
              ),
            ),
          ),
          if (history.values.every((list) => list.length < 2))
             Padding(
               padding: const EdgeInsets.only(top: 12.0),
               child: Text(
                 "Keep competing to see your trend",
                 style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
               ),
             ),
        ],
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode': return const Color(0xFFEF9F27);
      case 'codechef': return const Color(0xFF7B68EE);
      case 'github': return const Color(0xFF4078c0);
      case 'codeforces': return const Color(0xFFE24B4A);
      case 'hackerrank': return const Color(0xFF2EC866);
      default: return Colors.grey;
    }
  }
}
