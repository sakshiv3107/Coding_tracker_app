import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/leetcode_stats.dart';
import 'glass_card.dart';

class ContestTable extends StatelessWidget {
  final List<LeetCodeContestHistory> history;

  const ContestTable({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final sortedHistory = List<LeetCodeContestHistory>.from(history)
      ..sort((a, b) => b.date.compareTo(a.date));

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Performance History',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(theme.colorScheme.surface),
              columnSpacing: 24,
              columns: const [
                DataColumn(label: Text('CONTEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text('SOLVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text('RANK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                DataColumn(label: Text('RATING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
              rows: sortedHistory.map((h) {
                final solvedText = (h.solved != null && h.totalProblems != null)
                    ? '${h.solved}/${h.totalProblems}'
                    : (h.solved?.toString() ?? '-');
                return DataRow(
                  cells: [
                    DataCell(Text(h.contestTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    DataCell(Text(DateFormat('MMM dd').format(h.date), style: const TextStyle(fontSize: 11, color: Colors.grey))),
                    DataCell(Text(solvedText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    DataCell(Text('#${h.rank}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          h.rating.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}



