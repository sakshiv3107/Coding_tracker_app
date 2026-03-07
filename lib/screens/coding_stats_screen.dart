import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/submission_heatmap.dart';
import 'home/sections/leetcode_profile_card.dart';

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
      _refreshStats();
    });
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshStats(),
          color: AppTheme.primaryMint,
          child: CustomScrollView(
            slivers: [
              // Custom Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _buildBackButton(context),
                      const SizedBox(width: 20),
                      Text('LeetCode Stats', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      _buildRefreshButton(stats.isLoading),
                    ],
                  ),
                ),
              ),

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
              else if (stats.isLoading && stats.leetcodeStats == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryMint)),
                )
              else if (stats.leetcodeStats != null)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Profile Hero
                      LeetCodeProfileCard(stats: stats),
                      const SizedBox(height: 32),

                      // Activity Heatmap
                      SubmissionHeatmap(datasets: stats.leetcodeStats!.submissionCalendar),
                      const SizedBox(height: 32),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'SUBMISSIONS',
                              stats.leetcodeStats!.totalSolved.toString(),
                              Icons.check_circle_rounded,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'CONTEST RATING',
                              stats.leetcodeStats!.rating.toStringAsFixed(0),
                              Icons.trending_up_rounded,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'GLOBAL RANK',
                              '#${stats.leetcodeStats!.ranking}',
                              Icons.public_rounded,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'PERCENTILE',
                              'Top 5%', // Mocked for now
                              Icons.analytics_rounded,
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Difficulty Breakdown
                      Text('Difficulty Split', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      _buildDifficultySplit(stats.leetcodeStats!),

                      const SizedBox(height: 100), // Bottom padding
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.charcoal),
      ),
    );
  }

  Widget _buildRefreshButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryMintLight,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: isLoading ? null : _refreshStats,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryMint))
            : const Icon(Icons.refresh_rounded, size: 22, color: AppTheme.primaryMint),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDifficultySplit(var stats) {
    return Column(
      children: [
        _buildDifficultyProgressBar('Easy', stats.easy, 600, Colors.green),
        const SizedBox(height: 16),
        _buildDifficultyProgressBar('Medium', stats.medium, 1200, Colors.orange),
        const SizedBox(height: 16),
        _buildDifficultyProgressBar('Hard', stats.hard, 500, Colors.red),
      ],
    );
  }

  Widget _buildDifficultyProgressBar(String label, int solved, int total, Color color) {
    final percent = (solved / total).clamp(0.0, 1.0);
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$solved / $total', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
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
        color: AppTheme.errorRed.withOpacity(0.05),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, color: AppTheme.errorRed, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Connection Error', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.charcoal.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
