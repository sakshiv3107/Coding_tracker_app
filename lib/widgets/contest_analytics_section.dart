// widgets/contest_analytics_section.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/leetcode_stats.dart';
import 'modern_card.dart';

class ContestAnalyticsSection extends StatefulWidget {
  final LeetcodeStats stats;
  const ContestAnalyticsSection({super.key, required this.stats});

  @override
  State<ContestAnalyticsSection> createState() =>
      _ContestAnalyticsSectionState();
}

class _ContestAnalyticsSectionState extends State<ContestAnalyticsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool _datesAreCollapsed(List<LeetCodeContestHistory> history) {
    if (history.length < 2) return false;
    final ms = history.map((h) => h.date.millisecondsSinceEpoch).toList();
    final span = ms.reduce((a, b) => a > b ? a : b) -
        ms.reduce((a, b) => a < b ? a : b);
    return span < 604800000; // less than 1 week = collapsed
  }

  List<FlSpot> _buildSpots(List<LeetCodeContestHistory> history) {
    if (history.length == 1) return [FlSpot(50, history[0].rating)];

    if (_datesAreCollapsed(history)) {
      final step = 100.0 / (history.length - 1);
      return history
          .asMap()
          .entries
          .map((e) => FlSpot(e.key * step, e.value.rating))
          .toList();
    }

    final ms = history.map((h) => h.date.millisecondsSinceEpoch).toList();
    final earliest = ms.reduce((a, b) => a < b ? a : b).toDouble();
    final latest = ms.reduce((a, b) => a > b ? a : b).toDouble();
    final span = latest - earliest;
    return history.map((h) {
      final x = ((h.date.millisecondsSinceEpoch - earliest) / span) * 100;
      return FlSpot(x, h.rating);
    }).toList();
  }

  Map<String, double> _yearLabels(
      List<LeetCodeContestHistory> history, List<FlSpot> spots) {
    final labels = <String, double>{};
    if (_datesAreCollapsed(history)) {
      if (spots.isNotEmpty) labels['#1'] = spots.first.x;
      if (spots.length > 1) labels['#${spots.length}'] = spots.last.x;
      return labels;
    }
    for (int i = 0; i < history.length; i++) {
      final y = history[i].date.year.toString();
      if (!labels.containsKey(y)) labels[y] = spots[i].x;
    }
    return labels;
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final history = stats.contestHistory ?? [];

    final ratingText =
        (stats.contestRating != null && stats.contestRating! > 0)
            ? stats.contestRating!.toStringAsFixed(0)
            : 'N/A';

    return ModernCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stats row — use Wrap to prevent overflow ──────────────
          Wrap(
            spacing: 28,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              // Large rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contest Rating',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ratingText,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),

              // Global Ranking with rank/total
              if (stats.globalRanking != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Ranking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _fmt(stats.globalRanking!),
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          if (stats.topPercentage != null &&
                              stats.topPercentage! > 0)
                            TextSpan(
                              text:
                                  '/${_fmt((stats.globalRanking! / (stats.topPercentage! / 100)).round())}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (stats.topPercentage != null)
                      Text(
                        'Top ${stats.topPercentage!.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                  ],
                ),

              // Attended
              if (stats.totalContests != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attended',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalContests}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Chart ─────────────────────────────────────────────────
          // Only show chart if we have real history with distinct ratings
          if (history.length >= 2)
            _buildChart(history, isDark)
          else
            _buildNoChartMessage(stats),
        ],
      ),
    );
  }

  Widget _buildNoChartMessage(LeetcodeStats stats) {
    return Container(
      height: 60,
      alignment: Alignment.centerLeft,
      child: Text(
        history_isEmpty_reason(stats),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }

  String history_isEmpty_reason(LeetcodeStats stats) {
    final history = stats.contestHistory ?? [];
    if (history.isEmpty) return 'Contest history unavailable from API';
    if (history.length == 1) return 'Only 1 contest found — need 2+ to draw chart';
    return '';
  }

  Widget _buildChart(List<LeetCodeContestHistory> history, bool isDark) {
    final allSpots = _buildSpots(history);
    final yearLabels = _yearLabels(history, allSpots);

    final ratings = history.map((h) => h.rating).toList();
    final minR = ratings.reduce((a, b) => a < b ? a : b);
    final maxR = ratings.reduce((a, b) => a > b ? a : b);
    final pad = (minR == maxR)
        ? 100.0
        : ((maxR - minR) * 0.3).clamp(40.0, 180.0);

    final deduped = <double, FlSpot>{};
    for (final s in allSpots) deduped[s.x] = s;
    final cleanSpots = deduped.values.toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return SizedBox(
      height: 190,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final cutoff = _progress.value * 100.0;
          var visible = cleanSpots.where((s) => s.x <= cutoff).toList();
          if (visible.length < 2) return const SizedBox.shrink();

          return LineChart(
            duration: Duration.zero,
            LineChartData(
              minX: 0,
              maxX: 100,
              minY: minR - pad,
              maxY: maxR + pad,
              clipData: const FlClipData.all(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      for (final e in yearLabels.entries) {
                        if ((value - e.value).abs() < 8) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipRoundedRadius: 10,
                  tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  getTooltipItems: (touched) => touched.map((s) {
                    int best = 0;
                    double bestDist = double.infinity;
                    for (int i = 0; i < cleanSpots.length; i++) {
                      final d = (cleanSpots[i].x - s.x).abs();
                      if (d < bestDist) {
                        bestDist = d;
                        best = i;
                      }
                    }
                    final idx = best.clamp(0, history.length - 1);
                    return LineTooltipItem(
                      history[idx].rating.toStringAsFixed(0),
                      const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: visible,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: const Color(0xFFFFC01E),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, bar, idx) {
                      final isLast = idx == visible.length - 1;
                      return FlDotCirclePainter(
                        radius: isLast ? 5 : 3,
                        color: Colors.white,
                        strokeWidth: isLast ? 2.5 : 1.5,
                        strokeColor: const Color(0xFFFFC01E),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFC01E).withOpacity(0.20),
                        const Color(0xFFFFC01E).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}