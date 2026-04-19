import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rating_point.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class PlatformDonutChart extends StatefulWidget {
  final Map<String, int> platformSolvedCounts;
  final int weeklyTrend;
  final double percentile;

  const PlatformDonutChart({
    super.key, 
    required this.platformSolvedCounts,
    this.weeklyTrend = 12,
    this.percentile = 0.85, 
  });

  @override
  State<PlatformDonutChart> createState() => _PlatformDonutChartState();
}

class _PlatformDonutChartState extends State<PlatformDonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  // int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = widget.platformSolvedCounts.entries.where((e) => e.value > 0).toList();
    if (filteredData.isEmpty) return const SizedBox.shrink();
    final total = filteredData.fold<int>(0, (sum, e) => sum + e.value);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13162A).withOpacity(0.8) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.08 : 0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TOTAL SOLVED",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white.withOpacity(0.4) : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$total",
                            style: GoogleFonts.poppins(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTrendBadge(),
                        ],
                      ),
                    ),
                    _buildGlowingRing(filteredData, total),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPercentileRibbon(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.show_chart_rounded, size: 12, color: Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text(
            "+${widget.weeklyTrend} THIS WEEK",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingRing(List<MapEntry<String, int>> data, int total) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Soft Glow
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          
          // Outer Ring Chart
          PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 38,
              startDegreeOffset: 270,
              sections: data.map((e) {
                return PieChartSectionData(
                  color: _getPlatformColor(e.key),
                  value: e.value.toDouble(),
                  radius: 10,
                  showTitle: false,
                  badgeWidget: null,
                );
              }).toList(),
            ),
          ),

          // Center Filler
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withOpacity(0.03),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.code_rounded,
                size: 22,
                color: theme.colorScheme.primary.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentileRibbon() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "GLOBAL PERCENTILE",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.4) : theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "TOP ${(100 - (widget.percentile * 100)).toInt()}%",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF59E0B) : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 4,
              width: double.infinity,
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: const Duration(seconds: 1),
                        width: constraints.maxWidth * widget.percentile,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
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
      default: return Theme.of(context).colorScheme.primary;
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


