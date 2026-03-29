// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/achievement_provider.dart';
// import '../theme/app_theme.dart';
import '../widgets/unified_analytics_card.dart';
import '../widgets/profile_summary_card.dart';
import '../widgets/platform_quick_stats_grid.dart';
import '../widgets/coding_heatmap.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/weekly_activity_chart.dart';
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
    final achievementProvider = context.watch<AchievementProvider>();

    // ── LOADING GATE: never build with null profile ───────────────────────────
    if (profile.isLoading || profile.profile == null) {
      return const SafeArea(child: DashboardSkeleton());
    }

    // ── Safe data extraction ──────────────────────────────────────────────────
    final userName = auth.user?['name'] ?? 'Developer';
    final leetcodeUser = profile.profile?['leetcode'] ?? '';
    final githubUser = profile.profile?['github'] ?? '';
    final cfUser = profile.profile?['codeforces'] ?? '';
    final ccUser = profile.profile?['codechef'] ?? '';
    final hrUser = profile.profile?['hackerrank'] ?? '';
    final profilePic = profile.profile?['profilePic'];

    int connectedPlatforms = 0;
    if (leetcodeUser.isNotEmpty) connectedPlatforms++;
    if (githubUser.isNotEmpty) connectedPlatforms++;
    if (cfUser.isNotEmpty) connectedPlatforms++;
    if (ccUser.isNotEmpty) connectedPlatforms++;
    if (hrUser.isNotEmpty) connectedPlatforms++;

    final xp = stats.xpPoints;
    final level = (xp / 1000).floor() + 1;
    final progressToNextLevel = (xp % 1000) / 1000.0;

    // Heatmap merge
    final Map<DateTime, int> heatmapData = {};
    _mergeMap(heatmapData, stats.leetcodeStats?.submissionCalendar);
    _mergeMap(heatmapData, github.githubStats?.contributionCalendar);
    _mergeMap(heatmapData, stats.hackerrankStats?.submissionHistory);
    _mergeMap(heatmapData, stats.codechefStats?.submissionCalendar);

    final showRateLimitBanner = !_rateLimitBannerDismissed &&
        (stats.leetcodeRateLimited ||
            stats.codeforcesRateLimited ||
            stats.codechefRateLimited ||
            stats.hackerrankRateLimited);

    final avatarUrl = (profilePic != null && profilePic.isNotEmpty)
        ? profilePic
        : (stats.leetcodeStats?.avatar.isNotEmpty == true
            ? stats.leetcodeStats!.avatar
            : null);

    final tagStats = stats.leetcodeStats?.tagStats;
    final unlockedAchievements =
        List.from(achievementProvider.unlockedAchievements);

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
              stats.fetchUpcomingContests(cfHandle: cfUser, lcHandle: leetcodeUser),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                _buildHeader(context, theme, userName, xp, level, progressToNextLevel),
                const SizedBox(height: 16),

                // ── Rate Limit Banner ───────────────────────────────────────
                if (showRateLimitBanner) ...[
                  _buildRateLimitBanner(),
                  const SizedBox(height: 12),
                ],

                // ── Profile Summary ─────────────────────────────────────────
                ProfileSummaryCard(
                  name: userName,
                  leetcodeUser: leetcodeUser,
                  githubUser: githubUser,
                  totalPlatforms: connectedPlatforms,
                  profilePicUrl: avatarUrl,
                ),
                const SizedBox(height: 16),

                // ── Career Accelerator Banner ───────────────────────────────
                _buildCareerBanner(context),
                const SizedBox(height: 16),



                // ── Total Problems Solved ───────────────────────────────────
                UnifiedAnalyticsCard(
                  leetcode: stats.leetcodeStats?.totalSolved ?? 0,
                  codeforces: stats.codeforcesStats?.totalSolved ?? 0,
                  codechef: stats.codechefStats?.totalSolved ?? 0,
                  hackerrank: stats.hackerrankStats?.totalSolved ?? 0,
                  githubStars: github.githubStats?.totalStars ?? 0,
                  githubRepos: github.githubStats?.publicRepos ?? 0,
                ),
                const SizedBox(height: 16),

                // ── Platform Quick Stats ────────────────────────────────────
                PlatformQuickStatsGrid(
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
                    'rank': stats.codeforcesStats?.ranking,
                  },
                  codechef: {
                    'rating': stats.codechefStats?.rating,
                    'rank': stats.codechefStats?.ranking,
                  },
                  hackerrank: {
                    'solved': stats.hackerrankStats?.totalSolved,
                    'rank': stats.hackerrankStats?.ranking,
                  },
                  leetcodeLoading:
                      stats.leetcodeLoading && stats.leetcodeStats == null,
                  codeforcesLoading:
                      stats.codeforcesLoading && stats.codeforcesStats == null,
                  codechefLoading:
                      stats.codechefLoading && stats.codechefStats == null,
                  hackerrankLoading:
                      stats.hackerrankLoading && stats.hackerrankStats == null,
                  githubLoading:
                      github.isLoading && github.githubStats == null,
                  leetcodeRateLimited: stats.leetcodeRateLimited,
                  codeforcesRateLimited: stats.codeforcesRateLimited,
                  codechefRateLimited: stats.codechefRateLimited,
                  hackerrankRateLimited: stats.hackerrankRateLimited,
                  leetcodeError: stats.leetcodeError,
                  codeforcesError: stats.codeforcesError,
                  codechefError: stats.codechefError,
                  hackerrankError: stats.hackerrankError,
                  leetcodeNotSet: leetcodeUser.trim().isEmpty,
                  githubNotSet: githubUser.trim().isEmpty,
                  codeforcesNotSet: cfUser.trim().isEmpty,
                  codechefNotSet: ccUser.trim().isEmpty,
                  hackerrankNotSet: hrUser.trim().isEmpty,
                  onLeetCodeTap: () =>
                      Navigator.pushNamed(context, '/leetcode_stats'),
                  onGitHubTap: () =>
                      Navigator.pushNamed(context, '/github_stats'),
                  onCodeforcesTap: () =>
                      Navigator.pushNamed(context, '/codeforces_stats'),
                  onCodeChefTap: () =>
                      Navigator.pushNamed(context, '/codechef_stats'),
                  onHackerRankTap: () =>
                      Navigator.pushNamed(context, '/hackerrank_stats'),
                ),
                const SizedBox(height: 16),

                
                // ── Achievements ────────────────────────────────────────────
                if (unlockedAchievements.isNotEmpty) ...[
                  _buildAchievementsSection(
                      context, theme, unlockedAchievements),
                  const SizedBox(height: 16),
                ],

                // ── Activity Heatmap ────────────────────────────────────────
                CodingHeatmap(datasets: heatmapData),
                const SizedBox(height: 16),

                // ── Weekly Activity Chart ───────────────────────────────────
                WeeklyActivityChart(
                  leetcodeCalendar:
                      stats.leetcodeStats?.submissionCalendar ?? {},
                  githubCalendar:
                      github.githubStats?.contributionCalendar ?? {},
                  hackerrankCalendar:
                      stats.hackerrankStats?.submissionHistory ?? {},
                  codechefCalendar:
                      stats.codechefStats?.submissionCalendar ?? {},
                ),
                const SizedBox(height: 16),

                // ── Skill Radar Chart ───────────────────────────────────────
                if (tagStats != null && tagStats.isNotEmpty) ...[
                  SkillRadarChart(tagStats: tagStats),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),
                // ── AI Coding Insights ──────────────────────────────────────
                AIInsightsCard(
                  leetcodeSolved: stats.leetcodeStats?.totalSolved ?? 0,
                  githubCommits:
                      github.githubStats?.totalContributions ?? 0,
                  tagStats: stats.leetcodeStats?.tagStats ?? {},
                  easy: stats.leetcodeStats?.easy ?? 0,
                  medium: stats.leetcodeStats?.medium ?? 0,
                  hard: stats.leetcodeStats?.hard ?? 0,
                  recommendation: stats.aiRecommendation,
                ),
                const SizedBox(height: 16),

              ],

              
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-builders ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ThemeData theme, String userName,
      int xp, int level, double progress) {
    return Row(
      children: [
        Builder(builder: (ctx) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.grey.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          );
        }),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${userName.split(' ').first}!',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Keep up the grind 🔥',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // XP badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: theme.colorScheme.tertiary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: theme.colorScheme.tertiary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'LVL $level',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.tertiary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.tertiary),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRateLimitBanner() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded,
              color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'API rate limit reached. Showing cached data. Pull to retry.',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _rateLimitBannerDismissed = true),
            child: const Icon(Icons.close_rounded,
                color: Colors.amber, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerBanner(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/resume'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Career Accelerator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Export your coding portfolio to PDF',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, ThemeData theme,
      List<dynamic> achievements) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.tertiary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: theme.colorScheme.tertiary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${achievements.length} earned',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              itemBuilder: (context, i) {
                if (i >= achievements.length) return const SizedBox();
                final a = achievements[i];
                return Tooltip(
                  message: (a.description as String?) ?? '',
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.tertiary.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Icon(
                        (a.icon is IconData)
                            ? a.icon as IconData
                            : Icons.emoji_events_rounded,
                        color: theme.colorScheme.tertiary,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _mergeMap(Map<DateTime, int> target, Map<DateTime, int>? source) {
    if (source == null) return;
    for (final e in source.entries) {
      final d = DateTime(e.key.year, e.key.month, e.key.day);
      target[d] = (target[d] ?? 0) + e.value;
    }
  }
}
