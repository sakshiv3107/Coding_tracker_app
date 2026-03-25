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
  
  final String? leetcodeError;
  final String? codeforcesError;
  final String? codechefError;
  final String? gfgError;
  final String? hackerrankError;

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
    this.leetcodeError,
    this.codeforcesError,
    this.codechefError,
    this.gfgError,
    this.hackerrankError,
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
      childAspectRatio: 1.1,
      children: [
        _platformCard(
          context: context,
          title: 'LeetCode',
          icon: FontAwesomeIcons.code,
          color: AppTheme.leetCodeYellow,
          mainStat: '${leetcode['solved'] ?? 0} Solved',
          subStat: '${leetcode['easy'] ?? 0}E • ${leetcode['medium'] ?? 0}M',
          error: leetcodeError,
          onTap: onLeetCodeTap,
        ),
        _platformCard(
          context: context,
          title: 'GitHub',
          icon: FontAwesomeIcons.github,
          color: AppTheme.githubGrey,
          mainStat: '${github['repos'] ?? 0} Repos',
          subStat: '${github['commits'] ?? 0} Activity',
          onTap: onGitHubTap,
        ),
        _platformCard(
          context: context,
          title: 'Codeforces',
          icon: FontAwesomeIcons.chartSimple,
          color: Colors.blueAccent,
          mainStat: 'Rating: ${codeforces['rating'] ?? 'N/A'}',
          subStat: 'Rank: ${codeforces['rank'] ?? 'N/A'}',
          error: codeforcesError,
          onTap: onCodeforcesTap,
        ),
        _platformCard(
          context: context,
          title: 'CodeChef',
          icon: FontAwesomeIcons.terminal,
          color: Colors.brown,
          mainStat: 'Rating: ${codechef['rating'] ?? 'N/A'}',
          subStat: 'Rank: ${codechef['rank'] ?? 'N/A'}',
          error: codechefError,
          onTap: onCodeChefTap,
        ),
        _platformCard(
          context: context,
          title: 'GeeksforGeeks',
          icon: FontAwesomeIcons.graduationCap,
          color: Colors.green,
          mainStat: 'Solved: ${gfg['solved'] ?? 0}',
          subStat: 'Score: ${gfg['score'] ?? 0}',
          error: gfgError,
          onTap: onGfgTap,
        ),
        _platformCard(
          context: context,
          title: 'HackerRank',
          icon: FontAwesomeIcons.hackerrank,
          color: const Color(0xFF2EC866),
          mainStat: 'Solved: ${hackerrank['solved'] ?? 0}',
          subStat: 'Rank: ${hackerrank['rank'] ?? 'N/A'}',
          error: hackerrankError,
          onTap: onHackerRankTap,
        ),
      ],
    );
  }

  Widget _platformCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required String mainStat,
    required String subStat,
    String? error,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = error != null && error.isNotEmpty;

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
                    color: (hasError ? Colors.red : color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FaIcon(
                    hasError ? FontAwesomeIcons.circleExclamation : icon, 
                    color: hasError ? Colors.redAccent : color, 
                    size: 18
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded, 
                  size: 10, 
                  color: AppTheme.textSecondaryDark.withOpacity(0.3)
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
                if (hasError)
                  Text(
                    'Update Required',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                else ...[
                  Text(
                    mainStat,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryDark.withOpacity(0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subStat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryDark.withOpacity(0.4),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
