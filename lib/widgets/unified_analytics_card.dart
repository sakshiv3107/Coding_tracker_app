import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/glassmorphic_container.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UnifiedAnalyticsCard extends StatelessWidget {
  final int leetcode;
  final int codeforces;
  final int codechef;
  final int hackerrank;
  final int githubStars;
  final int githubRepos;
  final VoidCallback? onTap;

  const UnifiedAnalyticsCard({
    super.key,
    required this.leetcode,
    required this.codeforces,
    required this.codechef,
    required this.hackerrank,
    required this.githubStars,
    required this.githubRepos,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSolved = leetcode + codeforces + codechef + hackerrank;

    return GlassmorphicContainer(
      padding: EdgeInsets.zero,
      borderRadius: 32,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUMULATIVE PROGRESS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          totalSolved.toString(),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 56,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'Total Problems Decimated',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 32,
                          startDegreeOffset: 270,
                          sections: _buildPieSections(theme),
                        ),
                      ),
                      Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary.withOpacity(0.5), size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  _buildPlatformRow('LeetCode', leetcode, AppTheme.leetCodeYellow),
                  _divider(),
                  _buildPlatformRow('Codeforces', codeforces, const Color(0xFF60A5FA)),
                  _divider(),
                  _buildPlatformRow('CodeChef', codechef, const Color(0xFFC084FC)),
                  _divider(),
                  _buildPlatformRow('HackerRank', hackerrank, const Color(0xFF34D399)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat('NODES', _countConnected(), Icons.hub_rounded, theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat('REPOS', githubRepos, Icons.folder_copy_rounded, const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 16, color: Colors.white.withOpacity(0.05));

  int _countConnected() {
    int count = 0;
    if (leetcode > 0) count++;
    if (codeforces > 0) count++;
    if (codechef > 0) count++;
    if (hackerrank > 0) count++;
    if (githubRepos > 0) count++;
    return count;
  }

  Widget _buildPlatformRow(String name, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2),
            ),
          ],
        ),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, dynamic value, dynamic icon, Color color) { // Changed to dynamic
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          icon is IconData 
              ? Icon(icon, color: color, size: 14)
              : FaIcon(icon, color: color, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: color.withOpacity(0.6), fontWeight: FontWeight.w900, letterSpacing: 1),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(ThemeData theme) {
    final total = leetcode + codeforces + codechef + hackerrank;
    if (total == 0) return [PieChartSectionData(color: Colors.white.withOpacity(0.1), value: 1, radius: 12, showTitle: false)];

    return [
      if (leetcode > 0)
        PieChartSectionData(color: AppTheme.leetCodeYellow, value: leetcode.toDouble(), radius: 12, showTitle: false),
      if (codeforces > 0)
        PieChartSectionData(color: Colors.blueAccent, value: codeforces.toDouble(), radius: 12, showTitle: false),
      if (codechef > 0)
        PieChartSectionData(color: const Color(0xFF8B4513), value: codechef.toDouble(), radius: 12, showTitle: false),
      if (hackerrank > 0)
        PieChartSectionData(color: const Color(0xFF2EC366), value: hackerrank.toDouble(), radius: 12, showTitle: false),
    ];
  }
}


