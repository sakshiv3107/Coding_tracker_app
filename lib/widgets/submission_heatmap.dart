// widgets/submission_heatmap.dart
// LeetCode-style submission heatmap — month-wise columns, 7 rows (Sun–Sat),
// rounded green squares, month labels, animated fade-in per cell.

import 'package:flutter/material.dart';

class SubmissionHeatmap extends StatefulWidget {
  final Map<DateTime, int> datasets;
  final Color baseColor;

  const SubmissionHeatmap({
    super.key,
    required this.datasets,
    this.baseColor = const Color(0xFF00B85E),
  });

  @override
  State<SubmissionHeatmap> createState() => _SubmissionHeatmapState();
}

class _SubmissionHeatmapState extends State<SubmissionHeatmap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Data helpers ───────────────────────────────────────────────────────────

  /// Returns the last 365 days worth of week-columns.
  /// Each column = one week (7 cells, Sun=0 … Sat=6).
  /// Returns list of months, each month = list of week-columns,
  /// each week = 7 nullable DateTimes.
  List<_MonthData> _buildMonthData() {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    // Start from 52 weeks ago, aligned to Sunday
    DateTime cursor = todayNorm.subtract(const Duration(days: 364));
    // Roll back to nearest Sunday
    cursor = cursor.subtract(Duration(days: cursor.weekday % 7));

    final months = <_MonthData>[];
    _MonthData? currentMonth;

    while (!cursor.isAfter(todayNorm)) {
      // Build one week column (Sun→Sat)
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = cursor.add(Duration(days: d));
        week.add(day.isAfter(todayNorm) ? null : day);
      }

      // Group into months by the first non-null day's month
      final representativeDay = week.firstWhere((d) => d != null,
          orElse: () => null);
      if (representativeDay != null) {
        final monthKey = '${representativeDay.year}-${representativeDay.month}';
        if (currentMonth == null || currentMonth.key != monthKey) {
          currentMonth = _MonthData(
            key: monthKey,
            label: _monthLabel(representativeDay.month),
            weeks: [],
          );
          months.add(currentMonth);
        }
        currentMonth.weeks.add(week);
      }

      cursor = cursor.add(const Duration(days: 7));
    }

    return months;
  }

  String _monthLabel(int month) {
    const labels = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return labels[month];
  }

  int _countForDay(DateTime? day) {
    if (day == null) return -1; // out of range
    final key = DateTime(day.year, day.month, day.day);
    return widget.datasets[key] ?? 0;
  }

  int get _totalSubmissions =>
      widget.datasets.values.fold(0, (sum, v) => sum + v);

  int get _activeDays => widget.datasets.length;

  int get _maxStreak {
    if (widget.datasets.isEmpty) return 0;
    final sorted = widget.datasets.keys.toList()..sort();
    int max = 1, cur = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        cur++;
        if (cur > max) max = cur;
      } else {
        cur = 1;
      }
    }
    return max;
  }

  // ── Color ──────────────────────────────────────────────────────────────────

  Color _cellColor(int count, bool isDark) {
    if (count < 0) return Colors.transparent; // future/padding
    final empty = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    if (count == 0) return empty;
    final base = widget.baseColor;
    if (count <= 2) return base.withValues(alpha: 0.3);
    if (count <= 5) return base.withValues(alpha: 0.5);
    if (count <= 9) return base.withValues(alpha: 0.75);
    return base;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final months = _buildMonthData();

    const cellSize = 11.0;
    const cellGap = 3.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coding Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                'Last 12 Months',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // ── Heatmap grid ─────────────────────────────────────────────
        FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: months.map((month) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week columns
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: month.weeks.map((week) {
                          return Padding(
                            padding: const EdgeInsets.only(right: cellGap),
                            child: Column(
                              children: List.generate(7, (dayIndex) {
                                final day = week[dayIndex];
                                final count = _countForDay(day);
                                final color = _cellColor(count, isDark);
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: cellGap),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(2.5),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      // Month label
                      Text(
                        month.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Legend ───────────────────────────────────────────────────
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Less',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
            const SizedBox(width: 4),
            ...[0, 2, 5, 9, 15].map((count) => Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: _cellColor(count, isDark),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                )),
            const SizedBox(width: 4),
            Text(
              'More',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, bool isDark) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthData {
  final String key;
  final String label;
  final List<List<DateTime?>> weeks;

  _MonthData({
    required this.key,
    required this.label,
    required this.weeks,
  });
}