import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

    final breakdown = widget.platformBreakdown?[date] ?? {};

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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('EEE, d MMM').format(date),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$count submissions",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
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
                                Text("${e.value}", style: GoogleFonts.inter(fontSize: 10)),
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
      _selectedCell = date;
    });
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode': return const Color(0xFFEF9F27);
      case 'codechef': return const Color(0xFF7B68EE);
      case 'github': return const Color(0xFF4078c0);
      default: return Colors.grey;
    }
  }

  Color _getCellColor(int count) {
    if (count == 0) return Theme.of(context).dividerColor.withOpacity(0.05);
    final base = const Color(0xFF7B68EE);
    if (count <= 2) return base.withOpacity(0.2);
    if (count <= 5) return base.withOpacity(0.4);
    if (count <= 9) return base.withOpacity(0.7);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Activity Heatmap",
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: _monthOffset < 12 ? () => setState(() => _monthOffset++) : null,
                  ),
                  Text(
                    "Last 12 Months",
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildGrid(context),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month - _monthOffset, now.day);
    final startDate = endDate.subtract(const Duration(days: 35 * 7)); // 35 weeks

    final weeks = <List<DateTime>>[];
    DateTime cursor = startDate.subtract(Duration(days: startDate.weekday % 7));

    for (int w = 0; w < 24; w++) {
      final week = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        week.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        key: ValueKey(_monthOffset),
        children: weeks.map((week) {
          return Column(
            children: week.map((date) {
              final count = widget.datasets[DateTime(date.year, date.month, date.day)] ?? 0;
              final isSelected = _selectedCell == DateTime(date.year, date.month, date.day);
              
              return GestureDetector(
                onTapDown: (details) => _showTooltip(context, date, details.globalPosition, count),
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: _getCellColor(count),
                    borderRadius: BorderRadius.circular(2),
                    border: isSelected ? Border.all(color: Colors.white, width: 1) : null,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Less", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(width: 4),
        ...[0, 2, 5, 9, 15].map((c) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _getCellColor(c),
            borderRadius: BorderRadius.circular(2),
          ),
        )),
        const SizedBox(width: 4),
        Text("More", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
