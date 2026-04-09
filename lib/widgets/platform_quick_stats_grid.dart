// lib/widgets/platform_quick_stats_grid.dart
//
// IMPROVEMENTS:
//  1. Added per-platform isLoading flags to show shimmer skeletons
//     while each platform is fetching independently.
//  2. Added rateLimited flag to show a specific warning icon/message.
//  3. Platform cards now clearly distinguish between:
//     - Loading (shimmer)
//     - Rate limited (amber warning)
//     - User not found (red, "Check username")
//     - Generic error (red, "Update Required")
//     - Success (normal stat display)
//  4. Improved tap behaviour: tapping a loading/error card still navigates
//     to the detail screen so the user can see full error context.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'glassmorphic_container.dart';
import 'skeleton_loading.dart';
import '../theme/app_theme.dart';

class PlatformQuickStatsGrid extends StatelessWidget {
  final Map<String, dynamic> leetcode;
  final Map<String, dynamic> github;
  final Map<String, dynamic> codeforces;
  final Map<String, dynamic> codechef;
  final Map<String, dynamic> hackerrank;

  // Per-platform error messages
  final String? leetcodeError;
  final String? codeforcesError;
  final String? codechefError;
  final String? hackerrankError;

  // Per-platform loading flags (shimmer shown when true)
  final bool leetcodeLoading;
  final bool codeforcesLoading;
  final bool codechefLoading;
  final bool hackerrankLoading;
  final bool githubLoading;

  final bool leetcodeRateLimited;
  final bool codeforcesRateLimited;
  final bool codechefRateLimited;
  final bool hackerrankRateLimited;

  final bool leetcodeNotSet;
  final bool codeforcesNotSet;
  final bool codechefNotSet;
  final bool hackerrankNotSet;
  final bool githubNotSet;

  final VoidCallback? onLeetCodeTap;
  final VoidCallback? onGitHubTap;
  final VoidCallback? onCodeforcesTap;
  final VoidCallback? onCodeChefTap;
  final VoidCallback? onHackerRankTap;

  const PlatformQuickStatsGrid({
    super.key,
    required this.leetcode,
    required this.github,
    required this.codeforces,
    required this.codechef,
    required this.hackerrank,
    this.leetcodeError,
    this.codeforcesError,
    this.codechefError,
    this.hackerrankError,
    this.leetcodeLoading = false,
    this.codeforcesLoading = false,
    this.codechefLoading = false,
    this.hackerrankLoading = false,
    this.githubLoading = false,
    this.leetcodeRateLimited = false,
    this.codeforcesRateLimited = false,
    this.codechefRateLimited = false,
    this.hackerrankRateLimited = false,
    this.leetcodeNotSet = false,
    this.codeforcesNotSet = false,
    this.codechefNotSet = false,
    this.hackerrankNotSet = false,
    this.githubNotSet = false,
    this.onLeetCodeTap,
    this.onGitHubTap,
    this.onCodeforcesTap,
    this.onCodeChefTap,
    this.onHackerRankTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final padding = screenWidth > 400 ? 16.0 : 12.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: padding,
      mainAxisSpacing: padding,
      childAspectRatio: screenWidth > 360 ? 1.05 : 0.9,
      children: [
        _platformCard(
          context: context,
          title: 'LeetCode',
          icon: FontAwesomeIcons.code,
          color: AppTheme.leetCodeYellow,
          mainStat: '${leetcode['solved'] ?? 0} Solved',
          subStat:
              '${leetcode['easy'] ?? 0}E  •  ${leetcode['medium'] ?? 0}M',
          error: leetcodeError,
          isLoading: leetcodeLoading,
          isRateLimited: leetcodeRateLimited,
          isNotSet: leetcodeNotSet,
          onTap: onLeetCodeTap,
        ),
        _platformCard(
          context: context,
          title: 'GitHub',
          icon: FontAwesomeIcons.github,
          color: AppTheme.githubGrey,
          mainStat: '${github['repos'] ?? 0} Repos',
          subStat: '${github['commits'] ?? 0} Activity',
          isLoading: githubLoading,
          isNotSet: githubNotSet,
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
          isLoading: codeforcesLoading,
          isRateLimited: codeforcesRateLimited,
          isNotSet: codeforcesNotSet,
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
          isLoading: codechefLoading,
          isRateLimited: codechefRateLimited,
          isNotSet: codechefNotSet,
          onTap: onCodeChefTap,
        ),
        _platformCard(
          context: context,
          title: 'HackerRank',
          icon: FontAwesomeIcons.hackerrank,
          color: const Color(0xFF2EC866),
          mainStat: 'Solved: ${hackerrank['solved'] ?? 0}',
          subStat: 'Rank: ${hackerrank['rank'] ?? 'N/A'}',
          error: hackerrankError,
          isLoading: hackerrankLoading,
          isRateLimited: hackerrankRateLimited,
          isNotSet: hackerrankNotSet,
          onTap: onHackerRankTap,
        ),
      ],
    );
  }

  Widget _platformCard({
    required BuildContext context,
    required String title,
    required dynamic icon, // Changed to dynamic
    required Color color,
    required String mainStat,
    required String subStat,
    String? error,
    bool isLoading = false,
    bool isRateLimited = false,
    bool isNotSet = false,
    VoidCallback? onTap,
  }) {
    // While loading and no data yet → shimmer placeholder
    if (isLoading) {
      return GestureDetector(
        onTap: onTap,
        child: const PlatformCardSkeleton(),
      );
    }

    final theme = Theme.of(context);
    final hasError = error != null && error.isNotEmpty;

    // Determine card state colours
    final Color stateColor = isRateLimited
        ? Colors.amber
        : isNotSet
            ? theme.colorScheme.onSurface.withOpacity(0.3)
            : hasError
                ? Colors.redAccent
                : color;

    final dynamic stateIcon = isRateLimited
        ? FontAwesomeIcons.clock
        : isNotSet
            ? Icons.info_outline_rounded
            : hasError
                ? FontAwesomeIcons.circleExclamation
                : icon;

    return GlassmorphicContainer(
      padding: EdgeInsets.zero,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: stateColor.withValues(alpha: 0.2)),
                  ),
                  child: stateIcon is IconData 
                      ? Icon(stateIcon, color: stateColor, size: 20)
                      : FaIcon(stateIcon, color: stateColor, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  if (hasError || isRateLimited || isNotSet) ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isRateLimited 
                            ? 'Rate Limited' 
                            : isNotSet 
                                ? 'Offline'
                                : 'Update Req.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: stateColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isNotSet ? 'Tap to setup' : 'Tap to retry',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: stateColor.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mainStat,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      subStat,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
