import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/modern_card.dart';
import '../theme/app_theme.dart';

class UnifiedAnalyticsCard extends StatelessWidget {
  final int leetcode;
  final int codeforces;
  final int codechef;
  final int gfg;
  final int githubStars;
  final int githubRepos;

  const UnifiedAnalyticsCard({
    super.key,
    required this.leetcode,
    required this.codeforces,
    required this.codechef,
    required this.gfg,
    required this.githubStars,
    required this.githubRepos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSolved = leetcode + codeforces + codechef + gfg;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Problems Solved',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(totalSolved.toString(),
                      style: theme.textTheme.headlineLarge?.copyWith(color: AppTheme.primary)),
                ],
              ),
              Container(
                height: 80,
                width: 80,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 25,
                    sections: _buildPieSections(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _buildPlatformRow('LeetCode', leetcode, AppTheme.leetCodeYellow),
          _buildPlatformRow('Codeforces', codeforces, Colors.blueAccent),
          _buildPlatformRow('CodeChef', codechef, Colors.brown),
          _buildPlatformRow('GFG', gfg, Colors.green),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('Connected Platforms', _countConnected(), Icons.hub_rounded, Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStat('GitHub Repos', githubRepos, Icons.folder_copy_rounded, AppTheme.githubGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countConnected() {
    int count = 0;
    if (leetcode > 0) count++;
    if (codeforces > 0) count++;
    if (codechef > 0) count++;
    if (gfg > 0) count++;
    if (githubRepos > 0) count++;
    return count;
  }

  Widget _buildPlatformRow(String name, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(count.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(label, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = leetcode + codeforces + codechef + gfg;
    if (total == 0) return [PieChartSectionData(color: Colors.grey.shade300, value: 1, showTitle: false)];

    return [
      if (leetcode > 0)
        PieChartSectionData(color: AppTheme.leetCodeYellow, value: leetcode.toDouble(), radius: 8, showTitle: false),
      if (codeforces > 0)
        PieChartSectionData(color: Colors.blueAccent, value: codeforces.toDouble(), radius: 8, showTitle: false),
      if (codechef > 0)
        PieChartSectionData(color: Colors.brown, value: codechef.toDouble(), radius: 8, showTitle: false),
      if (gfg > 0)
        PieChartSectionData(color: Colors.green, value: gfg.toDouble(), radius: 8, showTitle: false),
    ];
  }
}
