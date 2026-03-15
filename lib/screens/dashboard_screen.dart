// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../providers/achievement_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/animations/animated_stat_counter.dart';
import '../widgets/developer_score_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/recent_submission_section.dart';
import '../widgets/app_drawer.dart';
import '../widgets/unified_analytics_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();
    final userName = auth.user?["name"] ?? "Developer";

    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final leetcodeUser = profile.profile?["leetcode"] ?? "";
            final githubUser = profile.profile?["github"] ?? "";
            final cfUser = profile.profile?["codeforces"] ?? "";
            final ccUser = profile.profile?["codechef"] ?? "";
            final gfgUser = profile.profile?["gfg"] ?? "";
            
            await stats.fetchAllStats(
              leetcode: leetcodeUser,
              codeforces: cfUser,
              codechef: ccUser,
              gfg: gfgUser,
            );
            
            if (githubUser.isNotEmpty)
              context.read<GithubProvider>().fetchGithubData(githubUser);
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ───────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (context) => IconButton(
                                onPressed: () => Scaffold.of(context).openDrawer(),
                                icon: const Icon(Icons.menu_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: theme.colorScheme.surface,
                                  elevation: 0,
                                ),
                              ),
                            ),
                            Hero(
                              tag: 'profile_avatar',
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AppTheme.primary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person_rounded,
                                    color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            Text(userName,
                                style: theme.textTheme.headlineMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Unified Analytics ────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 80),
                    child: UnifiedAnalyticsCard(
                      leetcode: stats.leetcodeStats?.totalSolved ?? 0,
                      codeforces: stats.codeforcesStats?.totalSolved ?? 0,
                      codechef: stats.codechefStats?.totalSolved ?? 0,
                      gfg: stats.gfgStats?.totalSolved ?? 0,
                      githubStars: github.githubStats?.totalStars ?? 0,
                      githubRepos: github.githubStats?.publicRepos ?? 0,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Streak card (compact) ─────────────────────────────────────
              if (stats.leetcodeStats != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 110),
                      child: StreakCard(
                        currentStreak:
                            stats.leetcodeStats!.streak,
                        maxStreak:
                            stats.leetcodeStats!.longestStreak,
                        compact: true,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Developer Score ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 120),
                    child: DeveloperScoreCard(
                      leetcodeSolved:
                          stats.leetcodeStats?.totalSolved ?? 0,
                      leetcodeRating:
                          stats.leetcodeStats?.rating ?? 0,
                      githubStars:
                          github.githubStats?.totalStars ?? 0,
                      githubContributions:
                          github.githubStats?.totalContributions ?? 0,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Weekly activity chart ─────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 150),
                    child: _buildAnalyticsSection(context, stats, github),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Platform cards ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Learning Path',
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 16),
                        _buildPlatformCards(context, stats, github),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Recent Submissions (home screen, limit 5) ─────────────────
              if (stats.leetcodeStats?.recentSubmissions != null &&
                  stats.leetcodeStats!.recentSubmissions!.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 250),
                      child: RecentSubmissionsSection(
                        submissions:
                            stats.leetcodeStats!.recentSubmissions!,
                        limit: 5,
                        showTitle: true,
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Achievements ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 300),
                    child: _buildAchievementsSection(context),
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

  // ── Weekly activity (unchanged from original) ─────────────────────────────

  Widget _buildAnalyticsSection(
    BuildContext context,
    StatsProvider leetcode,
    GithubProvider github,
  ) {
    final theme = Theme.of(context);
    final isDataLoading = leetcode.isLoading || github.isLoading;

    List<double> lcData = List.filled(7, 0.0);
    List<double> ghData = List.filled(7, 0.0);

    final now = DateTime.now();
    final startDate =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final key = DateTime(date.year, date.month, date.day);
      lcData[i] = (leetcode.leetcodeStats?.submissionCalendar[key] ?? 0).toDouble();
      ghData[i] = (github.githubStats?.contributionCalendar[key] ?? 0).toDouble();
    }

    double maxVal = 5.0;
    for (var v in [...lcData, ...ghData]) if (v > maxVal) maxVal = v;
    maxVal = (maxVal * 1.2).ceilToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Weekly Coding Activity', style: theme.textTheme.titleLarge),
            Row(
              children: [
                if (isDataLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primary),
                  ),
                const SizedBox(width: 12),
                _legendDot(AppTheme.leetCodeYellow, 'LC'),
                const SizedBox(width: 12),
                _legendDot(AppTheme.githubGrey, 'GH'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ModernCard(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          showShadow: true,
          showBorder: false,
          child: SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData:
                      BarTouchTooltipData(tooltipBgColor: theme.colorScheme.surface),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7) return const SizedBox();
                        final date = startDate.add(Duration(days: index));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: lcData[i],
                      color: AppTheme.leetCodeYellow,
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: ghData[i],
                      color: AppTheme.githubGrey,
                      width: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }


  Widget _buildPlatformCards(
      BuildContext context, StatsProvider stats, GithubProvider github) {
    return Column(
      children: [
        _PlatformTile(
          name: 'LeetCode',
          icon: FontAwesomeIcons.code,
          color: AppTheme.leetCodeYellow,
          stats: stats.leetcodeStats != null
              ? '${stats.leetcodeStats!.totalSolved} Solved'
              : 'Not Syncing',
          onTap: () => Navigator.pushNamed(context, '/leetcode_stats'),
        ),
        const SizedBox(height: 12),
         _PlatformTile(
          name: 'Codeforces',
          icon: Icons.trending_up_rounded,
          color: Colors.blueAccent,
          stats: stats.codeforcesStats != null
              ? '${stats.codeforcesStats!.totalSolved} Solved'
              : 'Not Syncing',
          onTap: () => Navigator.pushNamed(context, '/codeforces_stats'),
        ),
        const SizedBox(height: 12),
        _PlatformTile(
          name: 'CodeChef',
          icon: Icons.restaurant_menu_rounded,
          color: Colors.brown,
          stats: stats.codechefStats != null
              ? '${stats.codechefStats!.totalSolved} Solved'
              : 'Not Syncing',
          onTap: () => Navigator.pushNamed(context, '/codechef_stats'),
        ),
        const SizedBox(height: 12),
         _PlatformTile(
          name: 'GeeksforGeeks',
          icon: Icons.school_rounded,
          color: Colors.green,
          stats: stats.gfgStats != null
              ? '${stats.gfgStats!.totalSolved} Solved'
              : 'Not Syncing',
          onTap: () => Navigator.pushNamed(context, '/gfg_stats'),
        ),
        const SizedBox(height: 12),
        _PlatformTile(
          name: 'GitHub',
          icon: FontAwesomeIcons.github,
          color: AppTheme.githubGrey,
          stats: github.githubStats != null
              ? '${github.githubStats!.publicRepos} Repositories'
              : 'Not Syncing',
          onTap: () => Navigator.pushNamed(context, '/github_stats'),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    final achievementProvider = context.watch<AchievementProvider>();
    final theme = Theme.of(context);
    final unlocked = achievementProvider.unlockedAchievements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Achievements', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: () {},
              child: const Text('View all',
                  style: TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (unlocked.isEmpty)
          ModernCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No achievements yet. Keep coding!',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: unlocked.length,
              itemBuilder: (context, index) {
                final achievement = unlocked[index];
                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  child: ModernCard(
                    padding: const EdgeInsets.all(16),
                    showShadow: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(achievement.icon,
                              color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          achievement.title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _StatGridItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final String suffix;

  const _StatGridItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      showBorder: false,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedStatCounter(
                  value: value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              if (suffix.isNotEmpty)
                Text(suffix,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String stats;
  final VoidCallback onTap;

  const _PlatformTile({
    required this.name,
    required this.icon,
    required this.color,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: FaIcon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text(
                  stats,
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}