import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../glass_card.dart';
import '../../theme/app_theme.dart';

class ActivityHeatmap extends StatefulWidget {
  final Map<DateTime, int> datasets;
  final Map<DateTime, Map<String, int>>? platformBreakdown;

  const ActivityHeatmap({
    super.key,
    required this.datasets,
    this.platformBreakdown,
  });

  @override
  State<ActivityHeatmap> createState() => _ActivityHeatmapState();
}

class _ActivityHeatmapState extends State<ActivityHeatmap> {
  int _monthOffset = 0;
  OverlayEntry? _tooltipEntry;
  DateTime? _selectedCell;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  void _hideTooltip() {
    _tooltipEntry?.remove();
    _tooltipEntry = null;
    setState(() {
      _selectedCell = null;
    });
  }

  void _showTooltip(BuildContext context, DateTime date, Offset globalOffset, int count) {
    _hideTooltip();

    final breakdown = widget.platformBreakdown?[DateTime(date.year, date.month, date.day)] ?? {};
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _tooltipEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideTooltip,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: globalOffset.dx - 60,
            top: globalOffset.dy - 100,
            child: Material(
              color: Colors.transparent,
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('EEE, d MMM').format(date),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$count submissions",
                      style: TextStyle(fontSize: 11, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                    if (breakdown.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: breakdown.entries.map((e) {
                          Color pColor = _getPlatformColor(e.key);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text("${e.value}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_tooltipEntry!);
    setState(() {
      _selectedCell = DateTime(date.year, date.month, date.day);
    });
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode': return const Color(0xFFFFA116);
      case 'codechef': return const Color(0xFF5B4638);
      case 'github': return const Color(0xFF4078c0);
      case 'codeforces': return Colors.blue;
      case 'hackerrank': return const Color(0xFF2EC866);
      default: return Colors.grey;
    }
  }

  Color _getCellColor(int count, bool isDark) {
    if (count == 0) return isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final base = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    if (count <= 2) return base.withOpacity(0.2);
    if (count <= 5) return base.withOpacity(0.4);
    if (count <= 9) return base.withOpacity(0.7);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Activity Flux",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _monthOffset < 12 ? () => setState(() => _monthOffset++) : null,
                  ),
                  Text(
                    "Time Offset",
                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: _monthOffset > 0 ? () => setState(() => _monthOffset--) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGrid(context, isDark),
          const SizedBox(height: 12),
          _buildLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isDark) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month - _monthOffset, now.day);
    final startDate = endDate.subtract(const Duration(days: 34 * 7)); 

    final weeks = <List<DateTime>>[];
    DateTime cursor = startDate.subtract(Duration(days: startDate.weekday % 7));

    for (int w = 0; w < 35; w++) {
      final week = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        week.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: weeks.map((week) {
          return Column(
            children: week.map((date) {
              final normDate = DateTime(date.year, date.month, date.day);
              final count = widget.datasets[normDate] ?? 0;
              final isSelected = _selectedCell == normDate;
              
              return GestureDetector(
                onTapDown: (details) => _showTooltip(context, date, details.globalPosition, count),
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: _getCellColor(count, isDark),
                    borderRadius: BorderRadius.circular(2),
                    border: isSelected ? Border.all(color: isDark ? Colors.white : Colors.black, width: 1) : null,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Less", style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
        const SizedBox(width: 4),
        ...[0, 2, 5, 9, 15].map((c) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: _getCellColor(c, isDark),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(width: 4),
        Text("More", style: TextStyle(fontSize: 10, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
      ],
    );
  }
}


