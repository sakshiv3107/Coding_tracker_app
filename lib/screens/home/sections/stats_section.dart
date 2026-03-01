import 'package:flutter/material.dart';
import '../../../providers/stats_provider.dart';
import '../widgets/stat_card.dart';

class StatsSection extends StatelessWidget {
  final StatsProvider stats;
  final ThemeData theme;
  final bool isSmallScreen;

  const StatsSection({
    super.key,
    required this.stats,
    required this.theme,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
    crossAxisCount: isSmallScreen ? 2 : 4,
      crossAxisSpacing: isSmallScreen ? 12 : 16,
      mainAxisSpacing: isSmallScreen ? 12 : 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: isSmallScreen ? 1.0 : 1.2,
      children: [
        StatCard(
          title: 'Total Problems',
          value: stats.leetcodeStats?.totalSolved.toString() ?? "-",
          icon: Icons.list_alt,
          color: theme.colorScheme.primary,
        ),
        StatCard(
          title: 'Current Streak',
          value: '0',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        ),
        StatCard(
          title: 'Contests',
          value: '0',
          icon: Icons.emoji_events,
          color: Colors.purple,
        ),
        StatCard(
          title: 'Commits',
          value: '0',
          icon: Icons.code,
          color: Colors.teal,
        ),
      ],
    );
  }
}