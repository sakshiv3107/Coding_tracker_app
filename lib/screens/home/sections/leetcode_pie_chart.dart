import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/stats_provider.dart';

class LeetCodePieChart extends StatelessWidget {
  final StatsProvider stats;

  const LeetCodePieChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final easy = stats.leetcodeStats?.easy ?? 0;
    final medium = stats.leetcodeStats?.medium ?? 0;
    final hard = stats.leetcodeStats?.hard ?? 0;

    final total = easy + medium + hard;

    if (total == 0) {
      return const Center(
        child: Text("No stats available"),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Problem Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 50,
                  sections: [
                    PieChartSectionData(
                      value: easy.toDouble(),
                      color: Colors.green,
                      title: "Easy\n$easy",
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: medium.toDouble(),
                      color: Colors.orange,
                      title: "Medium\n$medium",
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: hard.toDouble(),
                      color: Colors.red,
                      title: "Hard\n$hard",
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}