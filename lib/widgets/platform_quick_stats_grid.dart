import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home/platform_stat_card.dart';

class PlatformQuickStatsGrid extends StatelessWidget {
  final Map<String, dynamic> leetcode;
  final Map<String, dynamic> github;
  final Map<String, dynamic> codeforces;
  final Map<String, dynamic> codechef;
  final Map<String, dynamic> hackerrank;

  final String? leetcodeError;
  final String? codeforcesError;
  final String? codechefError;
  final String? hackerrankError;

  final bool leetcodeLoading;
  final bool codeforcesLoading;
  final bool codechefLoading;
  final bool hackerrankLoading;
  final bool githubLoading;

  final String leetcodeUsername;
  final String githubUsername;
  final String codeforcesUsername;
  final String codechefUsername;
  final String hackerrankUsername;

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
    this.leetcodeUsername = '',
    this.githubUsername = '',
    this.codeforcesUsername = '',
    this.codechefUsername = '',
    this.hackerrankUsername = '',
    this.onLeetCodeTap,
    this.onGitHubTap,
    this.onCodeforcesTap,
    this.onCodeChefTap,
    this.onHackerRankTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlatformStatCard(
          platformName: 'LeetCode',
          username: leetcodeUsername,
          primaryStat: '${leetcode['solved'] ?? 0} Solved',
          secondaryStat: '${leetcode['easy'] ?? 0}E  •  ${leetcode['medium'] ?? 0}M',
          dailyActivity: [0, 2, 5, 3, 8, 4, 6], 
          platformColor: const Color(0xFFEF9F27),
          icon: const FaIcon(FontAwesomeIcons.code, size: 18, color: Color(0xFFEF9F27)),
          isLoading: leetcodeLoading,
          error: leetcodeError,
          onRetry: onLeetCodeTap,
          onConnect: onLeetCodeTap,
          onTap: onLeetCodeTap,
        ),
        const SizedBox(height: 12),
        PlatformStatCard(
          platformName: 'GitHub',
          username: githubUsername,
          primaryStat: '${github['repos'] ?? 0} Repos',
          secondaryStat: '${github['commits'] ?? 0} Activity',
          dailyActivity: [1, 4, 2, 7, 5, 3, 9],
          platformColor: const Color(0xFF4078c0),
          icon: const FaIcon(FontAwesomeIcons.github, size: 18, color: Color(0xFF4078c0)),
          isLoading: githubLoading,
          onRetry: onGitHubTap,
          onConnect: onGitHubTap,
          onTap: onGitHubTap,
        ),
        const SizedBox(height: 12),
        PlatformStatCard(
          platformName: 'Codeforces',
          username: codeforcesUsername,
          primaryStat: 'Rating: ${codeforces['rating'] ?? 'N/A'}',
          secondaryStat: 'Rank: ${codeforces['rank'] ?? 'N/A'}',
          dailyActivity: [0, 0, 1, 0, 0, 0, 0],
          platformColor: const Color(0xFFE24B4A),
          icon: const FaIcon(FontAwesomeIcons.chartSimple, size: 18, color: Color(0xFFE24B4A)),
          isLoading: codeforcesLoading,
          error: codeforcesError,
          onRetry: onCodeforcesTap,
          onConnect: onCodeforcesTap,
          onTap: onCodeforcesTap,
        ),
        const SizedBox(height: 12),
        PlatformStatCard(
          platformName: 'CodeChef',
          username: codechefUsername,
          primaryStat: 'Rating: ${codechef['rating'] ?? 'N/A'}',
          secondaryStat: 'Rank: ${codechef['rank'] ?? 'N/A'}',
          dailyActivity: [1, 0, 0, 2, 0, 3, 1],
          platformColor: const Color(0xFF7B68EE),
          icon: const FaIcon(FontAwesomeIcons.terminal, size: 18, color: Color(0xFF7B68EE)),
          isLoading: codechefLoading,
          error: codechefError,
          onRetry: onCodeChefTap,
          onConnect: onCodeChefTap,
          onTap: onCodeChefTap,
        ),
        const SizedBox(height: 12),
        PlatformStatCard(
          platformName: 'HackerRank',
          username: hackerrankUsername,
          primaryStat: '${hackerrank['solved'] ?? 0} Solved',
          secondaryStat: 'Rank: ${hackerrank['rank'] ?? 'N/A'}',
          dailyActivity: [2, 1, 3, 0, 4, 1, 2],
          platformColor: const Color(0xFF2EC866),
          icon: const FaIcon(FontAwesomeIcons.hackerrank, size: 18, color: Color(0xFF2EC866)),
          isLoading: hackerrankLoading,
          error: hackerrankError,
          onRetry: onHackerRankTap,
          onConnect: onHackerRankTap,
          onTap: onHackerRankTap,
        ),
      ],
    );
  }
}
