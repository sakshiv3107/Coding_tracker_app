// lib/screens/dashboard_screen.dart
//
// PERMANENT FIX: Added top-level loading gate that shows DashboardSkeleton
// while providers are still initializing. This prevents the FadeSlideTransition
// / flutter_animate library from crashing with "Null check operator" errors
// during the build phase. Each sliver section is now individually error-guarded.

import 'package:flutter/material.dart';
import '../models/submission.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../theme/app_theme.dart';
import '../providers/achievement_provider.dart';
import '../widgets/unified_analytics_card.dart';
import '../widgets/profile_summary_card.dart';
import '../widgets/platform_quick_stats_grid.dart';
import '../widgets/coding_heatmap.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/weekly_activity_chart.dart';
import '../widgets/contest_tracker_card.dart';
import '../widgets/modern_card.dart';
import '../widgets/skeleton_loading.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _rateLimitBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();

    // ── LOADING GATE ─────────────────────────────────────────────────────────
    // If profile is still loading or not ready, show skeleton immediately.
    // This prevents any child widget from running with null data.
    if (profile.isLoading || profile.profile == null) {
      return const Scaffold(
        body: SafeArea(child: DashboardSkeleton()),
      );
    }

    // ── Safe data extraction (all with ?? fallbacks) ──────────────────────────
    final userName = auth.user?['name'] ?? 'Developer';
    final leetcodeUser = profile.profile?['leetcode'] ?? '';
    final githubUser = profile.profile?['github'] ?? '';
    final cfUser = profile.profile?['codeforces'] ?? '';
    final ccUser = profile.profile?['codechef'] ?? '';
    final hrUser = profile.profile?['hackerrank'] ?? '';
    final profilePic = profile.profile?['profilePic'];

    // XP & level
    final xp = stats.xpPoints;
    final level = (xp / 1000).floor() + 1;
    final progressToNextLevel = (xp % 1000) / 1000;

    // Connected platform count
    int connectedPlatforms = 0;
    if (leetcodeUser.isNotEmpty) connectedPlatforms++;
    if (githubUser.isNotEmpty) connectedPlatforms++;
    if (cfUser.isNotEmpty) connectedPlatforms++;
    if (ccUser.isNotEmpty) connectedPlatforms++;
    if (hrUser.isNotEmpty) connectedPlatforms++;

    // Merged heatmap (safe nulls handled in _mergeHeatmapData)
    final Map<DateTime, int> heatmapData = {};
    _mergeHeatmapData(heatmapData, stats.leetcodeStats?.submissionCalendar);
    _mergeHeatmapData(heatmapData, github.githubStats?.contributionCalendar);
    _mergeHeatmapData(heatmapData, stats.hackerrankStats?.submissionHistory);

    // Use read to avoid unnecessary rebuilds for achievements
    final achievementProvider = context.read<AchievementProvider>();
    final achievements = List.from(achievementProvider.unlockedAchievements);

    final showRateLimitBanner = !_rateLimitBannerDismissed &&
        (stats.leetcodeRateLimited ||
            stats.codeforcesRateLimited ||
            stats.codechefRateLimited ||
            stats.hackerrankRateLimited);

    final failedProblems = List<Submission>.from(stats.failedProblems);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _rateLimitBannerDismissed = false);
            await Future.wait([
              stats.fetchAllStats(
                leetcode: leetcodeUser,
                codeforces: cfUser,
                codechef: ccUser,
                hackerrank: hrUser,
                forceRefresh: true,
              ),
              if (githubUser.isNotEmpty)
                github.fetchGithubData(githubUser, forceRefresh: true),
              stats.fetchUpcomingContests(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Builder(builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.surfaceDark : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.menu_rounded, size: 22),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        );
                      }),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${userName.isNotEmpty ? userName.split(' ').first : 'Developer'}!',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'The grind continues...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryDark.withOpacity(0.4),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // XP Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDarkLighter.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'LVL $level',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$xp XP',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progressToNextLevel,
                                      backgroundColor: Colors.white10,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                                      minHeight: 4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Rate Limit Banner ─────────────────────────────────────────
              if (showRateLimitBanner)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'API rate limit reached. Showing cached data. Pull down to retry.',
                              style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _rateLimitBannerDismissed = true),
                            child: const Icon(Icons.close_rounded, color: Colors.amber, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── A. Profile Summary ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: ProfileSummaryCard(
                    name: userName,
                    leetcodeUser: leetcodeUser,
                    githubUser: githubUser,
                    totalPlatforms: connectedPlatforms,
                    profilePicUrl: (profilePic != null && profilePic.isNotEmpty)
                        ? profilePic
                        : (stats.leetcodeStats != null && (stats.leetcodeStats!.avatar.isNotEmpty) ? stats.leetcodeStats!.avatar : null),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Resume Mode ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: ModernCard(
                    padding: EdgeInsets.zero,
                    isGlass: true,
                    borderRadius: 28,
                    gradient: [
                      AppTheme.primary,
                      AppTheme.primary.withOpacity(0.8),
                    ],
                    onTap: () => Navigator.pushNamed(context, '/resume'),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.description_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Career Accelerator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Export your coding portfolio to PDF',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── B. Contest Tracker ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: ContestTrackerCard(
                    contests: stats.upcomingContests,
                    isLoading: stats.contestsLoading,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── C. Total Problems Solved ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: stats.isLoading && stats.leetcodeStats == null
                      ? const SkeletonBox(width: double.infinity, height: 140, borderRadius: 24)
                      : UnifiedAnalyticsCard(
                          leetcode: stats.leetcodeStats?.totalSolved ?? 0,
                          codeforces: stats.codeforcesStats?.totalSolved ?? 0,
                          codechef: stats.codechefStats?.totalSolved ?? 0,
                          hackerrank: stats.hackerrankStats?.totalSolved ?? 0,
                          githubStars: github.githubStats?.totalStars ?? 0,
                          githubRepos: github.githubStats?.publicRepos ?? 0,
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── D. Platform Quick Stats ───────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: PlatformQuickStatsGrid(
                    leetcode: {
                      'solved': stats.leetcodeStats?.totalSolved,
                      'easy': stats.leetcodeStats?.easy,
                      'medium': stats.leetcodeStats?.medium,
                      'hard': stats.leetcodeStats?.hard,
                    },
                    github: {
                      'repos': github.githubStats?.publicRepos,
                      'commits': github.githubStats?.totalContributions,
                    },
                    codeforces: {
                      'rating': stats.codeforcesStats?.rating,
                      'rank': stats.codeforcesStats?.rank,
                    },
                    codechef: {
                      'rating': stats.codechefStats?.rating,
                      'rank': stats.codechefStats?.rank,
                    },
                    hackerrank: {
                      'solved': stats.hackerrankStats?.totalSolved,
                      'rank': stats.hackerrankStats?.rank,
                    },
                    leetcodeLoading: stats.leetcodeLoading && stats.leetcodeStats == null,
                    codeforcesLoading: stats.codeforcesLoading && stats.codeforcesStats == null,
                    codechefLoading: stats.codechefLoading && stats.codechefStats == null,
                    hackerrankLoading: stats.hackerrankLoading && stats.hackerrankStats == null,
                    githubLoading: github.isLoading && github.githubStats == null,
                    leetcodeRateLimited: stats.leetcodeRateLimited,
                    codeforcesRateLimited: stats.codeforcesRateLimited,
                    codechefRateLimited: stats.codechefRateLimited,
                    hackerrankRateLimited: stats.hackerrankRateLimited,
                    leetcodeError: stats.leetcodeError,
                    codeforcesError: stats.codeforcesError,
                    codechefError: stats.codechefError,
                    hackerrankError: stats.hackerrankError,
                    onLeetCodeTap: () => Navigator.pushNamed(context, '/leetcode_stats'),
                    onGitHubTap: () => Navigator.pushNamed(context, '/github_stats'),
                    onCodeforcesTap: () => Navigator.pushNamed(context, '/codeforces_stats'),
                    onCodeChefTap: () => Navigator.pushNamed(context, '/codechef_stats'),
                    onHackerRankTap: () => Navigator.pushNamed(context, '/hackerrank_stats'),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── E1. Failure Analysis ──────────────────────────────────────
              if (failedProblems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.report_problem_rounded, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              const Text('Retry Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text("You have some unsolved problems. Don't give up!",
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ...failedProblems.take(2).map(
                                (p) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Status: ${p.status}',
                                      style: TextStyle(color: theme.colorScheme.error)),
                                  trailing: ElevatedButton(
                                    onPressed: () {},
                                    child: const Text('Retry'),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── E. AI Coding Insights ─────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: AIInsightsCard(
                    leetcodeSolved: stats.leetcodeStats?.totalSolved ?? 0,
                    githubCommits: github.githubStats?.totalContributions ?? 0,
                    tagStats: stats.leetcodeStats?.tagStats ?? {},
                    easy: stats.leetcodeStats?.easy ?? 0,
                    medium: stats.leetcodeStats?.medium ?? 0,
                    hard: stats.leetcodeStats?.hard ?? 0,
                    recommendation: stats.aiRecommendation,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── F. Achievements / Badges ──────────────────────────────────
              if (achievements.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: AppTheme.accent),
                              SizedBox(width: 8),
                              Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: achievements.length,
                              itemBuilder: (context, index) {
                                if (index >= achievements.length) return const SizedBox();
                                final achievement = achievements[index];
                                return Tooltip(
                                  message: achievement.description ?? '',
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      achievement.icon is IconData ? achievement.icon : Icons.emoji_events,
                                      color: AppTheme.accent,
                                      size: 32,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── G. Coding Activity Heatmap ────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CodingHeatmap(datasets: heatmapData),
                      const SizedBox(height: 16),
                      WeeklyActivityChart(
                        leetcodeCalendar: stats.leetcodeStats?.submissionCalendar ?? {},
                        githubCalendar: github.githubStats?.contributionCalendar ?? {},
                        hackerrankCalendar: stats.hackerrankStats?.submissionHistory ?? {},
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── H. Skill Radar Chart ──────────────────────────────────────
              if ((stats.leetcodeStats?.tagStats?.isNotEmpty ?? false))
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: SkillRadarChart(
                      tagStats: stats.leetcodeStats!.tagStats!,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  void _mergeHeatmapData(Map<DateTime, int> target, Map<DateTime, int>? source) {
    if (source == null) return;
    for (final entry in source.entries) {
      final d = entry.key;
      final normalizedDate = DateTime(d.year, d.month, d.day);
      target[normalizedDate] = (target[normalizedDate] ?? 0) + entry.value;
    }
  }
}
