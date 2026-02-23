import 'package:flutter/material.dart';
import '../../../providers/stats_provider.dart';

class DifficultySection extends StatelessWidget {
  final StatsProvider stats;

  const DifficultySection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LeetCode Difficulty Split',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        const SizedBox(height: 16),
        _buildDifficultySplit(context, isSmallScreen),
      ],
    );
  }

  Widget _buildDifficultySplit(
    BuildContext context,
    bool isSmallScreen,
  ) {
    if (isSmallScreen) {
      return Column(
        children: [
          _difficultyCard(
            context,
            'Easy',
            stats.leetcodeStats?.easy.toString() ?? "-",
            Colors.green,
          ),
          const SizedBox(height: 12),
          _difficultyCard(
            context,
            'Medium',
            stats.leetcodeStats?.medium.toString() ?? "-",
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _difficultyCard(
            context,
            'Hard',
            stats.leetcodeStats?.hard.toString() ?? "-",
            Colors.red,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _difficultyCard(
            context,
            'Easy',
            stats.leetcodeStats?.easy.toString() ?? "-",
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _difficultyCard(
            context,
            'Medium',
            stats.leetcodeStats?.medium.toString() ?? "-",
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _difficultyCard(
            context,
            'Hard',
            stats.leetcodeStats?.hard.toString() ?? "-",
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _difficultyCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 16 : 20,
          horizontal: isSmallScreen ? 12 : 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: (isSmallScreen
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineMedium)
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
                fontSize: isSmallScreen ? 13 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}