import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class PlatformQuickStatsGrid extends StatelessWidget {
  final Map<String, dynamic> leetcode;
  final Map<String, dynamic> github;
  final Map<String, dynamic> codeforces;
  final Map<String, dynamic> codechef;
  final Map<String, dynamic> gfg;
  final Map<String, dynamic> hackerrank;
  final VoidCallback? onLeetCodeTap;
  final VoidCallback? onGitHubTap;
  final VoidCallback? onCodeforcesTap;
  final VoidCallback? onCodeChefTap;
  final VoidCallback? onGfgTap;
  final VoidCallback? onHackerRankTap;

  const PlatformQuickStatsGrid({
    super.key,
    required this.leetcode,
    required this.github,
    required this.codeforces,
    required this.codechef,
    required this.gfg,
    required this.hackerrank,
    this.onLeetCodeTap,
    this.onGitHubTap,
    this.onCodeforcesTap,
    this.onCodeChefTap,
    this.onGfgTap,
    this.onHackerRankTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1, // Better for premium look
      children: [
        _platformCard(
          context,
          'LeetCode',
          FontAwesomeIcons.code,
          AppTheme.leetCodeYellow,
          '${leetcode['solved'] ?? 0} Solved',
          '${leetcode['easy'] ?? 0}E • ${leetcode['medium'] ?? 0}M',
          onLeetCodeTap,
        ),
        _platformCard(
          context,
          'GitHub',
          FontAwesomeIcons.github,
          AppTheme.githubGrey,
          '${github['repos'] ?? 0} Repos',
          '${github['commits'] ?? 0} Activity',
          onGitHubTap,
        ),
        _platformCard(
          context,
          'Codeforces',
          FontAwesomeIcons.chartSimple,
          Colors.blueAccent,
          'Rating: ${codeforces['rating'] ?? 'N/A'}',
          'Rank: ${codeforces['rank'] ?? 'N/A'}',
          onCodeforcesTap,
        ),
        _platformCard(
          context,
          'CodeChef',
          FontAwesomeIcons.terminal,
          Colors.brown,
          'Rating: ${codechef['rating'] ?? 'N/A'}',
          'Rank: ${codechef['rank'] ?? 'N/A'}',
          onCodeChefTap,
        ),
        _platformCard(
          context,
          'GeeksforGeeks',
          FontAwesomeIcons.graduationCap,
          Colors.green,
          'Solved: ${gfg['solved'] ?? 0}',
          'Score: ${gfg['score'] ?? 0}',
          onGfgTap,
        ),
        _platformCard(
          context,
          'HackerRank',
          FontAwesomeIcons.hackerrank,
          const Color(0xFF2EC866),
          'Solved: ${hackerrank['solved'] ?? 0}',
          'Rank: ${hackerrank['rank'] ?? 'N/A'}',
          onHackerRankTap,
        ),
      ],
    );
  }

  Widget _platformCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String mainStat,
    String subStat,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: EdgeInsets.zero,
      isGlass: true,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FaIcon(icon, color: color, size: 18),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded, 
                  size: 10, 
                  color: AppTheme.textSecondaryDark.withValues(alpha: 0.3)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  mainStat,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimaryDark.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subStat,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryDark.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
