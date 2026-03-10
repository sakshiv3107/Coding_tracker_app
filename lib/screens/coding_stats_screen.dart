
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';
import '../models/leetcode_stats.dart';
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
import '../widgets/weekly_activity_chart.dart';
import '../widgets/contest_analytics_section.dart' hide AppTheme;
import 'package:intl/intl.dart';

class CodingStatsScreen extends StatefulWidget {
  const CodingStatsScreen({super.key});

  @override
  State<CodingStatsScreen> createState() => _CodingStatsScreenState();
}

class _CodingStatsScreenState extends State<CodingStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshStats());
  }

  void _refreshStats() {
    final profile = context.read<ProfileProvider>();
    final statsProvider = context.read<StatsProvider>();
    final username = profile.profile?["leetcode"] ?? "";

    if (username.isNotEmpty) {
      statsProvider.fetchLeetCodeStats(username);
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      const SizedBox(width: 16),
                      Text('LeetCode', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      _buildRefreshButton(stats.isLoading),
                    ],
                  ),
                ),
              ),

              // ── Error State ──────────────────────────────────────────
              if (stats.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _buildErrorBanner(stats.error!, _refreshStats),
                    ),
                  ),
                )

              // ── Loading Skeleton ──────────────────────────────────────
              else if (stats.isLoading && stats.leetcodeStats == null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SkeletonLoading(width: double.infinity, height: 180, borderRadius: 24),
                      const SizedBox(height: 16),
                      const SkeletonLoading(width: double.infinity, height: 130, borderRadius: 24),
                      const SizedBox(height: 16),
                      const SkeletonLoading(width: double.infinity, height: 200, borderRadius: 24),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                          SizedBox(width: 16),
                          Expanded(child: SkeletonLoading(width: double.infinity, height: 100, borderRadius: 24)),
                        ],
                      ),
                    ]),
                  ),
                )

              // ── Loaded Content ────────────────────────────────────────
              else if (stats.leetcodeStats != null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(_buildContent(stats, profile, github)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(StatsProvider stats, ProfileProvider profile, GithubProvider github) {
    final lc = stats.leetcodeStats!;

    return [
      // 1. Profile header
      FadeSlideTransition(
        child: _buildProfileHeader(stats, profile),
      ),
      const SizedBox(height: 24),

      // 2. Developer Score Card (NEW)
      FadeSlideTransition(
        delay: const Duration(milliseconds: 80),
        child: DeveloperScoreCard(
          leetcodeSolved: lc.totalSolved,
          leetcodeRating: lc.contestRating ?? 0,
          githubStars: github.githubStats?.totalStars ?? 0,
          githubContributions: github.githubStats?.totalContributions ?? 0,
        ),
      ),
      const SizedBox(height: 24),

      // 3. Streak section
      FadeSlideTransition(
        delay: const Duration(milliseconds: 120),
        child: StreakCard(
          currentStreak: lc.streak,
          maxStreak: lc.longestStreak,
        ),
      ),
      const SizedBox(height: 24),

      // 4. Main stats (total solved, active days, ranking)
      FadeSlideTransition(
        delay: const Duration(milliseconds: 160),
        child: _buildMainStats(stats),
      ),
      const SizedBox(height: 24),

      // 5. Difficulty breakdown (REPLACED with horizontal bar chart)
      FadeSlideTransition(
        delay: const Duration(milliseconds: 200),
        child: DifficultyBarChart(
          easy: lc.easy,
          medium: lc.medium,
          hard: lc.hard,
        ),
      ),
      const SizedBox(height: 24),

    
      // 6. Submission heatmap
      FadeSlideTransition(
        delay: const Duration(milliseconds: 280),
        child: SubmissionHeatmap(
          datasets: lc.submissionCalendar,
          baseColor: AppTheme.leetCodeYellow,
        ),
      ),
      const SizedBox(height: 32),

      // 7. Contest analytics — show if ANY contest data is available
      // contestRating > 0 means the user has participated in at least one contest
      if ((lc.contestRating != null && lc.contestRating! > 0) ||
          lc.globalRanking != null ||
          (lc.contestHistory != null && lc.contestHistory!.isNotEmpty)) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 300),
          child: Text('Contest Performance', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 16),
        FadeSlideTransition(
          delay: const Duration(milliseconds: 320),
          child: ContestAnalyticsSection(stats: lc),
        ),
        const SizedBox(height: 32),
      ],

      // 8. Contest table (keep existing)
      if (lc.contestHistory != null && lc.contestHistory!.isNotEmpty) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 400),
          child: ContestTable(history: lc.contestHistory!),
        ),
        const SizedBox(height: 32),
      ],

      // 9. Problem solving trend
      FadeSlideTransition(
        delay: const Duration(milliseconds: 360),
        child: ProblemSolvingTrendChart(
          submissionCalendar: lc.submissionCalendar,
        ),
      ),
      const SizedBox(height: 32),

      

      // 10. Recent submissions
      if (lc.recentSubmissions != null && lc.recentSubmissions!.isNotEmpty) ...[
        FadeSlideTransition(
          delay: const Duration(milliseconds: 440),
          child: RecentSubmissionsSection(
            submissions: lc.recentSubmissions!,
            limit: 10,
          ),
        ),
      ],

      const SizedBox(height: 120),
    ];
  }


  Widget _buildStreakSection(LeetcodeStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailedStatCard(
            'CURRENT STREAK',
            stats.streak,
            Icons.local_fire_department_rounded,
            Colors.orange,
            subtitle: 'Consecutive days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDetailedStatCard(
            'MAX STREAK',
            stats.longestStreak,
            Icons.emoji_events_rounded,
            Colors.amber,
            subtitle: 'Best record',
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStatCard(String title, int value, IconData icon, Color color,
      {String subtitle = ''}) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedStatCounter(
                value: value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(' d', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildMainStats(StatsProvider stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'TOTAL SOLVED',
            stats.leetcodeStats!.totalSolved,
            Icons.check_circle_rounded,
            AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'ACTIVE DAYS',
            stats.leetcodeStats!.activeDays,
            Icons.calendar_today_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'RANKING',
            stats.leetcodeStats!.ranking,
            Icons.public_rounded,
            Colors.purple,
            prefix: '#',
            isSmall: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSubmissions(List<RecentSubmission> submissions) {
    return Column(
      children: submissions.take(5).map((sub) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ModernCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (sub.status == 'Accepted' ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sub.status == 'Accepted' ? Icons.check_rounded : Icons.close_rounded,
                    color: sub.status == 'Accepted' ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        DateFormat('MMM dd, yyyy HH:mm').format(sub.timestamp),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  sub.status,
                  style: TextStyle(
                    color: sub.status == 'Accepted' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileHeader(StatsProvider stats, ProfileProvider profile) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.leetCodeYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.code_rounded, color: AppTheme.leetCodeYellow, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.profile?["leetcode"] ?? 'User',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'LeetCode Developer',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
            )
          : const Icon(Icons.refresh_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
        foregroundColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color,
      {String prefix = '', bool isSmall = false}) {
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
                  Text(prefix,
                      style: TextStyle(
                          fontSize: isSmall ? 12 : 14, fontWeight: FontWeight.bold)),
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

  Widget _buildErrorBanner(String message, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('Connection Error',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ),
        ],
      ),
    );
  }
}