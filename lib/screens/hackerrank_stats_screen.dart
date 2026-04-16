import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/hackerrank_stats.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/not_connected_widget.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/responsive_card.dart';
import '../widgets/platform_error_card.dart';

class HackerRankStatsScreen extends StatefulWidget {
  const HackerRankStatsScreen({super.key});

  @override
  State<HackerRankStatsScreen> createState() => _HackerRankStatsScreenState();
}

class _HackerRankStatsScreenState extends State<HackerRankStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshStats();
    });
  }

  Future<void> _refreshStats() async {
    final profile = context.read<ProfileProvider>();
    final stats = context.read<StatsProvider>();
    final username = profile.profile?["hackerrank"] ?? "";
    if (username.isNotEmpty) {
      await stats.fetchHackerRankStats(username, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = context.watch<StatsProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final stats = statsProvider.hackerrankStats;
    final isLoading = statsProvider.hackerrankLoading;
    final username = profileProvider.profile?["hackerrank"] ?? "";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('HackerRank Analytics'),
        backgroundColor: Colors.transparent,
        
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        color: const Color(0xFF2EC866),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (username.isEmpty)
              const NotConnectedWidget(
                platformName: 'HackerRank',
                icon: FontAwesomeIcons.hackerrank,
                color: Color(0xFF2EC866),
              )
            else if (isLoading && stats == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (stats != null) ...[
              // 1. Profile header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    child: _buildProfileHeader(stats, theme),
                  ),
                ),
              ),

              // 2. Main stats grid (Solved, Rank, Badges, Country)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 100),
                    child: _buildMainStatsGrid(stats),
                  ),
                ),
              ),

              // 3. Activity Heatmap (HackerRank Only)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 200),
                    child: ActivityHeatmap(
                      data: stats.submissionHistory,
                      baseColor: const Color(0xFF2EC866),
                      label: 'HackerRank Activity',
                      tooltipLabel: 'submissions',
                    ),
                  ),
                ),
              ),

              // 4. Platform Metrics
              if (stats.extraMetrics.isNotEmpty || stats.followers > 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: FadeSlideTransition(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(theme, 'Platform Metrics'),
                          const SizedBox(height: 12),
                          _buildPlatformMetricsGrid(stats, theme),
                        ],
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ] else if (statsProvider.hackerrankError != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: PlatformErrorCard(
                      platformName: 'HackerRank',
                      message: statsProvider.hackerrankError!,
                      onRetry: _refreshStats,
                      isUserNotFound: statsProvider.hackerrankUserNotFound,
                    ),
                  ),
                ),
              )
            else
              const SliverFillRemaining(
                child: Center(child: Text("No data available")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(HackerRankStats stats, ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2EC866).withOpacity(0.2), width: 3),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF2EC866).withOpacity(0.1),
              backgroundImage: (stats.avatarUrl != null && stats.avatarUrl!.isNotEmpty)
                  ? NetworkImage(stats.avatarUrl!)
                  : null,
              child: (stats.avatarUrl == null || stats.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 40, color: Color(0xFF2EC866))
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stats.username,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  'HackerRank Developer ${stats.country != null ? "• ${stats.country}" : ""}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildHeaderBadge(Icons.workspace_premium_rounded, '${stats.extraMetrics["badges_count"] ?? 0} Badges', Colors.orange),
                    _buildHeaderBadge(Icons.verified_user_rounded, 'Verified', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsGrid(HackerRankStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.25, // Responsive aspect ratio
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        ResponsiveCard(label: 'Solved', value: stats.totalSolved.toString(), icon: Icons.check_circle_outline_rounded, color: Colors.green),
        ResponsiveCard(label: 'Rank', value: stats.ranking ?? 'N/A', icon: Icons.trending_up_rounded, color: Colors.blue),
        ResponsiveCard(label: 'Badges', value: stats.extraMetrics["badges_count"]?.toString() ?? '0', icon: Icons.workspace_premium_rounded, color: Colors.orange),
        ResponsiveCard(label: 'Country', value: stats.country ?? 'N/A', icon: Icons.public_rounded, color: Colors.purple),
      ],
    );
  }



  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildPlatformMetricsGrid(HackerRankStats stats, ThemeData theme) {
    // Collect all extra metrics
    final metrics = <String, dynamic>{};
    if (stats.followers > 0) metrics['Followers'] = stats.followers;
    if (stats.extraMetrics['level'] != null) metrics['Level'] = stats.extraMetrics['level'];
    
    // Add any other dynamic items
    stats.extraMetrics.forEach((key, value) {
      if (key != 'badges_count' && key != 'level') {
        metrics[key] = value;
      }
    });

    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust column count based on width
        int crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2, // Consistent ratio
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final key = metrics.keys.elementAt(index);
            final value = metrics.values.elementAt(index);
            
            return ResponsiveCard(
              label: key,
              value: value.toString(),
              icon: Icons.analytics_rounded,
            );
          },
        );
      }
    );
  }
}


