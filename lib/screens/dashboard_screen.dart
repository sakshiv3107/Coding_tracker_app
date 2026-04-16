// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/goal_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/profile_summary_card.dart';
import '../widgets/platform_quick_stats_grid.dart';
import '../widgets/skill_radar_chart.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/home/home_header.dart';
import '../widgets/coding_heatmap.dart';
import '../widgets/weekly_activity_chart.dart' as old_chart;
import '../widgets/home/daily_challenge_card.dart';
import '../widgets/home/contest_countdown_card.dart';
import '../widgets/home/performance_analytics.dart';
import '../widgets/home/streak_alert_banner.dart';
import '../services/progress_service.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();


    // ── LOADING GATE: only show skeleton while intentionally loading from network ──
    if (profile.isLoading) {
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

    // final xp = stats.xpPoints;
    // final level = (xp / 1000).floor() + 1;
    // final progressToNextLevel = (xp % 1000) / 1000.0;

    // Heatmap merge
    final Map<DateTime, int> heatmapData = {};
    _mergeMap(heatmapData, stats.leetcodeStats?.submissionCalendar);
    _mergeMap(heatmapData, github.githubStats?.contributionCalendar);
    _mergeMap(heatmapData, stats.hackerrankStats?.submissionHistory);
    _mergeMap(heatmapData, stats.codechefStats?.submissionCalendar);

    // final showRateLimitBanner =
    //     !_rateLimitBannerDismissed &&
    //     (stats.leetcodeRateLimited ||
    //         stats.codeforcesRateLimited ||
    //         stats.codechefRateLimited ||
    //         stats.hackerrankRateLimited);

    final avatarUrl = (profilePic != null && profilePic.isNotEmpty)
        ? profilePic
        : (stats.leetcodeStats?.avatar.isNotEmpty == true
              ? stats.leetcodeStats!.avatar
              : null);

    final tagStats = stats.leetcodeStats?.tagStats;
    // final unlockedAchievements = List.from(
    //   achievementProvider.unlockedAchievements,
    // );

    final upcomingContests = stats.upcomingContests
        .where((c) {
          final diff = c.startTime.difference(DateTime.now());
          return diff.inHours <= 48 && !diff.isNegative;
        })
        .take(3)
        .toList();

    final goals = context.watch<GoalProvider>().goals;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(selectedIndex: 0),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Background Decorative Blobs ─────────────────────────────────────
          Positioned(
            top: -100,
            right: -50,
            child:
                RepaintBoundary(
                  child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.1
                                : 0.04,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .move(
                        begin: const Offset(0, 0),
                        end: const Offset(-20, 20),
                        duration: 10.seconds,
                      ),
                ),
          ),
          Positioned(
            top: 200,
            left: -100,
            child:
                RepaintBoundary(
                  child: Container(
                        width: 400,
                        height: 400,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.tertiary.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.08
                                : 0.03,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .move(
                        begin: const Offset(0, 0),
                        end: const Offset(30, -30),
                        duration: 15.seconds,
                      ),
                ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child:
                RepaintBoundary(
                  child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.secondary.withValues(
                            alpha: theme.brightness == Brightness.dark
                                ? 0.06
                                : 0.02,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .move(
                        begin: const Offset(0, 0),
                        end: const Offset(-40, -20),
                        duration: 12.seconds,
                      ),
                ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                final goalProvider = context.read<GoalProvider>();

                // Refresh all profile data in parallel first
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
                  stats.fetchUpcomingContests(
                    cfHandle: cfUser,
                    lcHandle: leetcodeUser,
                  ),
                ]);

                if (mounted) {
                  goalProvider.checkProgressAndNotifyCompletion(stats, github);
                }
              },

              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            icon: Icon(
                              Icons.menu_rounded,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 28,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StreakAlertBanner(
                              onSolveNow: () =>
                                  Navigator.pushNamed(context, '/leetcode_stats'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    sliver: SliverToBoxAdapter(
                      child: const HomeHeader()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideX(begin: -0.1),
                    ),
                  ),

                  // ── Profile Summary ─────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child:
                          RepaintBoundary(
                            child: ProfileSummaryCard(
                              name: userName,
                              leetcodeUser: leetcodeUser,
                              githubUser: githubUser,
                              totalPlatforms: connectedPlatforms,
                              profilePicUrl: avatarUrl,
                            ),
                          ).animate().scale(
                            delay: 100.ms,
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ),
                  ),

                  // ── Upcoming Contests ──────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: ContestCountdownCard(
                        contests: upcomingContests,
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ),
                  ),

                  // ── Daily Challenge ─────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: const DailyChallengeCard()
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.1),
                    ),
                  ),

                  // ── Active Goals ─────────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _sectionTitle(
                                  context,
                                  'Active Goals',
                                  Icons.flag_rounded,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/goals'),
                                  child: Text('Explore >', style: TextStyle(color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent),),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (goals.isEmpty)
                              const Text('No active goals tracking')
                            else
                              Column(
                                children: goals.take(2).map((goal) {
                                  final currentValue =
                                      ProgressService.calculateProgress(
                                        goal: goal,
                                        statsProvider: stats,
                                        githubProvider: github,
                                      );
                                  return _buildGoalProgressCard(
                                    context,
                                    goal,
                                    currentValue,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                            context,
                            'Performance Analytics',
                            Icons.analytics_rounded,
                          ),
                          const SizedBox(height: 12),
                          RepaintBoundary(
                            child: GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: PlatformDonutChart(
                                platformSolvedCounts: {
                                  'LeetCode': stats.leetcodeStats?.totalSolved ?? 0,
                                  'CodeForces':
                                      stats.codeforcesStats?.totalSolved ?? 0,
                                  'CodeChef': stats.codechefStats?.totalSolved ?? 0,
                                  'HackerRank':
                                      stats.hackerrankStats?.totalSolved ?? 0,
                                },
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Platform Quick Stats ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: RepaintBoundary(
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
                              stats.leetcodeLoading &&
                              stats.leetcodeStats == null,
                          codeforcesLoading:
                              stats.codeforcesLoading &&
                              stats.codeforcesStats == null,
                          codechefLoading:
                              stats.codechefLoading &&
                              stats.codechefStats == null,
                          hackerrankLoading:
                              stats.hackerrankLoading &&
                              stats.hackerrankStats == null,
                          githubLoading:
                              github.isLoading && github.githubStats == null,
                          leetcodeUsername: leetcodeUser,
                          githubUsername: githubUser,
                          codeforcesUsername: cfUser,
                          codechefUsername: ccUser,
                          hackerrankUsername: hrUser,
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
                      ),
                    ),
                  ),

                  // ── Visualizations ──────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                         // _buildSectionLabel(context, 'Activity Spectrum'),
                          const SizedBox(height: 12),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activity Heatmap',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                RepaintBoundary(
                                  child: CodingHeatmap(
                                    datasets: heatmapData,
                                    colorsets: {
                                      1: Theme.of(context).brightness == Brightness.dark
                                          ? AppTheme.darkAccent.withOpacity(0.3)
                                          : AppTheme.lightAccent.withOpacity(0.3),
                                      3: Theme.of(context).brightness == Brightness.dark
                                          ? AppTheme.darkAccent.withOpacity(0.6)
                                          : AppTheme.lightAccent.withOpacity(0.6),
                                      5: Theme.of(context).brightness == Brightness.dark
                                          ? AppTheme.darkAccent
                                          : AppTheme.lightAccent,
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: RepaintBoundary(
                              child: old_chart.WeeklyActivityChart(
                                leetcodeCalendar:
                                    stats.leetcodeStats?.submissionCalendar ?? {},
                                githubCalendar:
                                    github.githubStats?.contributionCalendar ?? {},
                                hackerrankCalendar:
                                    stats.hackerrankStats?.submissionHistory ?? {},
                                codechefCalendar:
                                    stats.codechefStats?.submissionCalendar ?? {},
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (tagStats != null && tagStats.isNotEmpty)
                            GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: RepaintBoundary(child: SkillRadarChart(tagStats: tagStats)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

 
  Widget _buildGoalProgressCard(
    BuildContext context,
    dynamic goal,
    int current,
  ) {
    final theme = Theme.of(context);
    final double progress = (current / goal.targetValue).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$current / ${goal.targetValue}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 6,
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


