import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> data;
  final Color baseColor;
  final String label;
  final String tooltipLabel;
  final bool showStats;
  final Map<int, Color>? colorsets;

  const ActivityHeatmap({
    super.key,
    required this.data,
    this.baseColor = Colors.green,
    this.label = 'Activity',
    this.tooltipLabel = 'contributions',
    this.showStats = true,
    this.colorsets,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: 364 + today.weekday % 7));
    
    // Group weeks into a list
    final List<List<DateTime>> weeks = [];
    List<DateTime> currentWeek = [];
    for (int i = 0; i <= today.difference(startDate).inDays; i++) {
      final date = startDate.add(Duration(days: i));
      currentWeek.add(date);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    // Group weeks by month for the "gapped" look
    final Map<String, List<List<DateTime>>> monthGroups = {};
    for (var week in weeks) {
        if (week.isEmpty) continue;
        final firstDay = week.first;
        final groupKey = DateFormat('yyyy-MM').format(firstDay);
        monthGroups.putIfAbsent(groupKey, () => []).add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showStats) ...[
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          _buildStatsHeader(context),
          const SizedBox(height: 16),
        ] else if (label.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 12.0),
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    _buildDayLabel(context, 'Mon'),
                    const SizedBox(height: 14),
                    _buildDayLabel(context, 'Wed'),
                    const SizedBox(height: 14),
                    _buildDayLabel(context, 'Fri'),
                  ],
                ),
              ),
              ...monthGroups.entries.map((entry) {
                final parts = entry.key.split('-');
                final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
                final monthName = DateFormat('MMM').format(date);
                return _buildMonthBlock(context, monthName, entry.value);
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildStatsHeader(BuildContext context) {
    final total = data.values.fold(0, (sum, v) => sum + v);
    final activeDays = data.values.where((v) => v > 0).length;
    
    int maxStreak = 0;
    int currentStreak = 0;
    final sortedDates = data.keys.toList()..sort();
    
    DateTime? lastDate;
    for (var date in sortedDates) {
      if ((data[date] ?? 0) > 0) {
        if (lastDate != null) {
          final diff = date.difference(lastDate).inDays;
          if (diff == 1) {
            currentStreak++;
          } else {
            currentStreak = 1;
          }
        } else {
          currentStreak = 1;
        }
        lastDate = date;
        if (currentStreak > maxStreak) maxStreak = currentStreak;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$tooltipLabel in the past one year',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _buildStatInfo(context, 'Total active days:', '$activeDays'),
              const SizedBox(width: 16),
              _buildStatInfo(context, 'Max streak:', '$maxStreak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(BuildContext context, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthBlock(BuildContext context, String monthLabel, List<List<DateTime>> monthWeeks) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: monthWeeks.map((week) => _buildWeekColumn(context, week)).toList(),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              monthLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(BuildContext context, String text) {
    return SizedBox(
      height: 12,
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10),
      ),
    );
  }

  Widget _buildWeekColumn(BuildContext context, List<DateTime> week) {
    return Column(
      children: week.map((date) => _HeatmapCell(
        date: date,
        count: data[DateTime(date.year, date.month, date.day)] ?? 0,
        baseColor: baseColor,
        tooltipLabel: tooltipLabel,
        colorsets: colorsets,
      )).toList(),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10)),
        _buildLegendSquare(0),
        _buildLegendSquare(1),
        _buildLegendSquare(3),
        _buildLegendSquare(6),
        _buildLegendSquare(10),
        Text('More', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10)),
      ],
    );
  }

  Widget _buildLegendSquare(int count) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: _getColor(count, baseColor, colorsets),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  static Color _getColor(int count, Color baseColor, [Map<int, Color>? colorsets]) {
    if (colorsets != null) {
      if (count == 0) return baseColor.withOpacity(0.05);
      if (count >= 10) return colorsets[5] ?? baseColor;
      if (count >= 5) return colorsets[3] ?? baseColor.withOpacity(0.6);
      return colorsets[1] ?? baseColor.withOpacity(0.3);
    }
    if (count == 0) return baseColor.withOpacity(0.05); 
    if (count < 3) return baseColor.withOpacity(0.15);
    if (count < 6) return baseColor.withOpacity(0.4);
    if (count < 10) return baseColor.withOpacity(0.7);
    return baseColor;
  }
}

class _HeatmapCell extends StatefulWidget {
  final DateTime date;
  final int count;
  final Color baseColor;
  final String tooltipLabel;
  final Map<int, Color>? colorsets;

  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.baseColor,
    required this.tooltipLabel,
    this.colorsets,
  });

  @override
  State<_HeatmapCell> createState() => _HeatmapCellState();
}

class _HeatmapCellState extends State<_HeatmapCell> {
  OverlayEntry? _overlayEntry;

  void _showTooltip() {
    _removeTooltip();
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 60,
        top: offset.dy - 45,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.count} ${widget.tooltipLabel}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(widget.date),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      _removeTooltip();
    });
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showTooltip,
      child: Container(
        width: 11,
        height: 11,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: ActivityHeatmap._getColor(widget.count, widget.baseColor, widget.colorsets),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}


