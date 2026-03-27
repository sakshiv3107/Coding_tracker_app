// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
// import '../models/leetcode_stats.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/submission_heatmap.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/animations/animated_stat_counter.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/problem_solving_trend_chart.dart';
import '../widgets/contest_table.dart';
import '../widgets/streak_card.dart';
import '../widgets/recent_submission_section.dart';
import '../widgets/developer_score_card.dart';
import '../widgets/difficulty_bar_chart.dart';
import '../widgets/contest_analytics_section.dart';
import '../widgets/badges_section.dart';
import '../widgets/not_connected_widget.dart';
import '../widgets/topic_wise_section.dart';
import '../widgets/recently_solved_section.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/app_drawer.dart';
import '../widgets/platform_error_card.dart';

class CodingStatsScreen extends StatefulWidget {
  const CodingStatsScreen({super.key});

  @override
  State<CodingStatsScreen> createState() => _CodingStatsScreenState();
}

class _CodingStatsScreenState extends State<CodingStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats = context.read<StatsProvider>();
      // Only fetch if no cached data — cache handles repeat visits
      if (stats.leetcodeStats == null && !stats.leetcodeLoading) {
        _refreshStats();
      }
    });
  }

  void _refreshStats() {
    final profile = context.read<ProfileProvider>();
    final statsProvider = context.read<StatsProvider>();
    final username = profile.profile?["leetcode"] ?? "";

    if (username.isNotEmpty) {
      // forceRefresh: true — bypasses cache on manual pull-to-refresh
      statsProvider.fetchLeetCodeStats(username, forceRefresh: true);
    } else {
      statsProvider.setError("LeetCode username not set in profile");
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final profile = context.watch<ProfileProvider>();
    final github = context.watch<GithubProvider>();
    final theme = Theme.of(context);
    final username = profile.profile?["leetcode"] ?? "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshStats(),
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Top Bar ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        _buildBackButton(context),
                        const SizedBox(width: 8),
                        _buildMenuButton(context),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LeetCode',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 24,
                                  letterSpacing: -1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Analytics Dashboard',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondaryDark.withOpacity(0.5),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRefreshButton(stats.leetcodeLoading),
                      ],
                    ),
                ),
              ),

              if (username.isEmpty)
                const NotConnectedWidget(
                  platformName: 'LeetCode',
                  icon: FontAwesomeIcons.code,
                  color: AppTheme.leetCodeYellow,
                )
              // ── Error State ──────────────────────────────────────────
              else if (stats.leetcodeError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: PlatformErrorCard(
                        platformName: 'LeetCode',
                        message: stats.leetcodeError!,
                        onRetry: _refreshStats,
                        isUserNotFound: stats.leetcodeUserNotFound,
                      ),
                    ),
                  ),
                )
              // ── Loading Skeleton ──────────────────────────────────────
              else if (stats.leetcodeLoading && stats.leetcodeStats == null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SkeletonLoading(
                        width: double.infinity,
                        height: 160,
                        borderRadius: 28,
                      ),
                      const SizedBox(height: 24),
                      const SkeletonLoading(
                        width: double.infinity,
                        height: 180,
                        borderRadius: 28,
                      ),
                      const SizedBox(height: 24),
                      const SkeletonLoading(
                        width: double.infinity,
                        height: 200,
                        borderRadius: 28,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                            child: SkeletonLoading(
                              width: double.infinity,
                              height: 120,
                              borderRadius: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: SkeletonLoading(
                              width: double.infinity,
                              height: 120,
                              borderRadius: 28,
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ),
                )
              // ── Main Content ──────────────────────────────────────────
              else if (stats.leetcodeStats != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildContent(stats, profile, github),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    StatsProvider stats,
    ProfileProvider profile,
    GithubProvider github,
  ) {
    final lc = stats.leetcodeStats;
    if (lc == null) return [const SizedBox.shrink()];

    return [
      // 1. Profile header
      FadeSlideTransition(child: _buildProfileHeader(stats, profile)),
      const SizedBox(height: 32),

      // 2. Overview Section
      const FadeSlideTransition(
        delay: Duration(milliseconds: 50),
        child: PremiumSectionHeader(
          title: 'Developer Insights',
          subtitle: 'A summary of your coding prowess',
          icon: FontAwesomeIcons.chartLine,
        ),
      ),
      const SizedBox(height: 12),
      FadeSlideTransition(
        delay: const Duration(milliseconds: 80),
        child: DeveloperScoreCard(
          totalSolved: lc.totalSolved,
          leetcodeRating: lc.contestRating ?? 0,
          githubStars: github.githubStats?.totalStars ?? 0,
          githubContributions: github.githubStats?.totalContributions ?? 0,
        ),
      ),
      const SizedBox(height: 24),
      FadeSlideTransition(
        delay: const Duration(milliseconds: 120),
        child: StreakCard(
          currentStreak: lc.streak,
          maxStreak: lc.longestStreak,
        ),
      ),
      const SizedBox(height: 24),
      FadeSlideTransition(
        delay: const Duration(milliseconds: 160),
        child: _buildMainStats(stats),
      ),
      const SizedBox(height: 40),

      // 3. Problem Solving Section
      const FadeSlideTransition(
        delay: Duration(milliseconds: 200),
        child: PremiumSectionHeader(
          title: 'Problem Solving',
          subtitle: 'Detailed breakdown by difficulty and tags',
          icon: FontAwesomeIcons.puzzlePiece,
        ),
      ),
      const SizedBox(height: 12),
      FadeSlideTransition(
        delay: const Duration(milliseconds: 220),
        child: DifficultyBarChart(
          easy: lc.easy,
          medium: lc.medium,
          hard: lc.hard,
        ),
      ),
      const SizedBox(height: 24),
      if (lc.tagStats != null) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 240),
          child: TopicWiseSection(tagStats: lc.tagStats!),
        ),
        const SizedBox(height: 24),
      ],
      FadeSlideTransition(
        delay: const Duration(milliseconds: 280),
        child: SubmissionHeatmap(
          datasets: lc.submissionCalendar,
          baseColor: AppTheme.leetCodeYellow,
        ),
      ),
      const SizedBox(height: 24),
      FadeSlideTransition(
        delay: const Duration(milliseconds: 300),
        child: ProblemSolvingTrendChart(
          submissionCalendar: lc.submissionCalendar,
        ),
      ),
      const SizedBox(height: 40),

      // 4. Contest Performance
      if ((lc.contestRating != null && lc.contestRating! > 0) ||
          lc.globalRanking != null ||
          (lc.contestHistory != null && lc.contestHistory!.isNotEmpty)) ...[
        const FadeSlideTransition(
          delay: Duration(milliseconds: 320),
          child: PremiumSectionHeader(
            title: 'Contest Performance',
            subtitle: 'Global standing and rating history',
            icon: FontAwesomeIcons.trophy,
            iconColor: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 340),
          child: ContestAnalyticsSection(stats: lc),
        ),
        const SizedBox(height: 24),
        if (lc.contestHistory != null && lc.contestHistory!.isNotEmpty) ...[
          FadeSlideTransition(
            delay: const Duration(milliseconds: 360),
            child: ContestTable(history: lc.contestHistory!),
          ),
          const SizedBox(height: 24),
        ],
        const SizedBox(height: 16),
      ],

      // 5. Activity & Achievements
      const FadeSlideTransition(
        delay: Duration(milliseconds: 380),
        child: PremiumSectionHeader(
          title: 'Recent Activity',
          subtitle: 'Your latest submissions and milestones',
          icon: FontAwesomeIcons.fire,
          iconColor: Colors.orange,
        ),
      ),
      const SizedBox(height: 12),
      if (lc.recentSubmissions != null) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 400),
          child: RecentlySolvedSection(submissions: lc.recentSubmissions!),
        ),
        const SizedBox(height: 24),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 440),
          child: RecentSubmissionsSection(
            submissions: lc.recentSubmissions!,
            limit: 10,
          ),
        ),
        const SizedBox(height: 24),
      ],
      if (lc.badges != null && lc.badges!.isNotEmpty) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 480),
          child: BadgesSection(badges: lc.badges!),
        ),
      ],

      const SizedBox(height: 120),
    ];
  }

  Widget _buildDetailedStatCard(
    String title,
    int value,
    IconData icon,
    Color color, {
    String subtitle = '',
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedStatCounter(
                value: value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' d',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  Widget _buildMainStats(StatsProvider stats) {
    final lc = stats.leetcodeStats!;
    return Row(
      children: [
        Expanded(
          child: PremiumStatCard(
            label: 'SOLVED',
            value: lc.totalSolved.toString(),
            icon: FontAwesomeIcons.checkDouble,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PremiumStatCard(
            label: 'RANKING',
            value: NumberFormat.compact().format(lc.ranking),
            icon: FontAwesomeIcons.globe,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(StatsProvider stats, ProfileProvider profile) {
    final lc = stats.leetcodeStats;
    if (lc == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final username = profile.profile?["leetcode"] ?? "";

    return ModernCard(
      padding: EdgeInsets.zero,
      isGlass: true,
      showShadow: true,
      child: Stack(
        children: [
          // Background Gradient Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              FontAwesomeIcons.code,
              size: 140,
              color: AppTheme.leetCodeYellow.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Avatar with premium ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.leetCodeYellow, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.cardTheme.color,
                    backgroundImage: NetworkImage(lc.avatar),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.leetCodeYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              FontAwesomeIcons.bolt,
                              size: 10,
                              color: AppTheme.leetCodeYellow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LEETCODE PRO',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.leetCodeYellow,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.profile?["name"] ?? "Standard Developer",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.at,
                            size: 12,
                            color: AppTheme.textSecondaryDark.withOpacity(0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            username,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryDark.withOpacity(0.7),
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
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: isDark ? Colors.white : AppTheme.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading) {
    return IconButton.filledTonal(
      onPressed: isLoading ? null : _refreshStats,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primary,
              ),
            )
          : const Icon(Icons.refresh_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.primary.withOpacity(0.1),
        foregroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Builder(
      builder: (context) {
        return Container(
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
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: Icon(
              Icons.menu_rounded,
              size: 18,
              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
    Color color, {
    String prefix = '',
    bool isSmall = false,
  }) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      showShadow: true,
      showBorder: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (prefix.isNotEmpty)
                  Text(
                    prefix,
                    style: TextStyle(
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                AnimatedStatCounter(
                  value: value,
                  style: TextStyle(
                    fontSize: isSmall ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

}
