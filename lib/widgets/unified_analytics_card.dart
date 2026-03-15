import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/modern_card.dart';
import '../theme/app_theme.dart';

class UnifiedAnalyticsCard extends StatelessWidget {
  final int leetcode;
  final int codeforces;
  final int codechef;
  final int gfg;
  final int hackerrank;
  final int githubStars;
  final int githubRepos;
  final VoidCallback? onTap;

  const UnifiedAnalyticsCard({
    super.key,
    required this.leetcode,
    required this.codeforces,
    required this.codechef,
    required this.gfg,
    required this.hackerrank,
    required this.githubStars,
    required this.githubRepos,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSolved = leetcode + codeforces + codechef + gfg + hackerrank;

    return ModernCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL PROBLEMS SOLVED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalSolved.toString(),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 42,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        startDegreeOffset: 270,
                        sections: _buildPieSections(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildPlatformRow('LeetCode', leetcode, AppTheme.leetCodeYellow),
                    _buildPlatformRow('Codeforces', codeforces, Colors.blueAccent),
                    _buildPlatformRow('CodeChef', codechef, const Color(0xFF5B4638)),
                    _buildPlatformRow('GeeksforGeeks', gfg, const Color(0xFF2F8D46)),
                    _buildPlatformRow('HackerRank', hackerrank, const Color(0xFF2EC866)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStat('PLATFORMS', _countConnected(), Icons.hub_rounded, Colors.indigo),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStat('REPOSITORIES', githubRepos, Icons.folder_copy_rounded, AppTheme.githubGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countConnected() {
    int count = 0;
    if (leetcode > 0) count++;
    if (codeforces > 0) count++;
    if (codechef > 0) count++;
    if (gfg > 0) count++;
    if (hackerrank > 0) count++;
    if (githubRepos > 0) count++;
    return count;
  }

  Widget _buildPlatformRow(String name, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: color.withOpacity(0.7), fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = leetcode + codeforces + codechef + gfg + hackerrank;
    if (total == 0) return [PieChartSectionData(color: Colors.grey.withOpacity(0.2), value: 1, radius: 10, showTitle: false)];

    return [
      if (leetcode > 0)
        PieChartSectionData(color: AppTheme.leetCodeYellow, value: leetcode.toDouble(), radius: 10, showTitle: false),
      if (codeforces > 0)
        PieChartSectionData(color: Colors.blueAccent, value: codeforces.toDouble(), radius: 10, showTitle: false),
      if (codechef > 0)
        PieChartSectionData(color: const Color(0xFF5B4638), value: codechef.toDouble(), radius: 10, showTitle: false),
      if (gfg > 0)
        PieChartSectionData(color: const Color(0xFF2F8D46), value: gfg.toDouble(), radius: 10, showTitle: false),
      if (hackerrank > 0)
        PieChartSectionData(color: const Color(0xFF2EC866), value: hackerrank.toDouble(), radius: 10, showTitle: false),
    ];
  }
}
