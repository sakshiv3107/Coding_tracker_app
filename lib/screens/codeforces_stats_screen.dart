import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/platform_stats.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/not_connected_widget.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/responsive_card.dart';
import '../widgets/platform_error_card.dart';
// import '../theme/app_theme.dart';

class CodeforcesStatsScreen extends StatefulWidget {
  const CodeforcesStatsScreen({super.key});

  @override
  State<CodeforcesStatsScreen> createState() => _CodeforcesStatsScreenState();
}

class _CodeforcesStatsScreenState extends State<CodeforcesStatsScreen> {
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
    final username = profile.profile?["codeforces"] ?? "";
    if (username.isNotEmpty) {
      await stats.fetchCodeforcesStats(username, forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statsProvider = context.watch<StatsProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final stats = statsProvider.codeforcesStats;
    final isLoading = statsProvider.codeforcesLoading;
    final username = profileProvider.profile?["codeforces"] ?? "";

    const platformColor = Color(0xFF1A73E8);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Codeforces Intelligence'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        color: platformColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (username.isEmpty)
              const NotConnectedWidget(
                platformName: 'Codeforces',
                icon: FontAwesomeIcons.code,
                color: platformColor,
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
                    child: _buildProfileHeader(stats, theme, platformColor),
                  ),
                ),
              ),

              // 2. Main stats grid (Solved, Rating, Max Rating, Rank)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 100),
                    child: _buildMainStatsGrid(stats),
                  ),
                ),
              ),

              // 3. Activity Heatmap
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 200),
                    child: ActivityHeatmap(
                      data: stats.submissionCalendar ?? {},
                      baseColor: platformColor,
                      label: 'Codeforces Activity',
                      tooltipLabel: 'submissions',
                    ),
                  ),
                ),
              ),

              // 4. Platform Metrics (if any extra)
              if (stats.extraMetrics.isNotEmpty)
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
            ] else if (statsProvider.codeforcesError != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: PlatformErrorCard(
                      platformName: 'Codeforces',
                      message: statsProvider.codeforcesError!,
                      onRetry: _refreshStats,
                      isUserNotFound: statsProvider.codeforcesUserNotFound,
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

  Widget _buildProfileHeader(PlatformStats stats, ThemeData theme, Color platformColor) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: platformColor.withOpacity(0.2), width: 3),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: platformColor.withOpacity(0.1),
              backgroundImage: (stats.avatarUrl != null && stats.avatarUrl!.isNotEmpty)
                  ? NetworkImage(stats.avatarUrl!)
                  : (stats.profileUrl != null && stats.profileUrl!.isNotEmpty && stats.profileUrl!.startsWith('http')
                      ? NetworkImage(stats.profileUrl!)
                      : null),
              child: (stats.avatarUrl == null || stats.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 40)
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
                  'Codeforces ${stats.ranking ?? "User"}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildHeaderBadge(Icons.emoji_events_rounded, '${stats.rating ?? 0} Rating', Colors.blue),
                    _buildHeaderBadge(Icons.workspace_premium_rounded, stats.ranking ?? 'Newbie', _getRankColor(stats.ranking)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(String? rank) {
    if (rank == null) return Colors.grey;
    final r = rank.toLowerCase();
    if (r.contains('legendary') || r.contains('international grandmaster')) return Colors.red;
    if (r.contains('grandmaster')) return Colors.redAccent;
    if (r.contains('master')) return Colors.orange;
    if (r.contains('candidate master')) return Colors.purple;
    if (r.contains('expert')) return Colors.blue;
    if (r.contains('specialist')) return Colors.cyan;
    if (r.contains('pupil')) return Colors.green;
    return Colors.grey;
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

  Widget _buildMainStatsGrid(PlatformStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.25,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        ResponsiveCard(label: 'Solved', value: stats.totalSolved.toString(), icon: Icons.check_circle_outline_rounded, color: Colors.green),
        ResponsiveCard(label: 'Rating', value: stats.rating?.toString() ?? '0', icon: Icons.emoji_events_rounded, color: Colors.blue),
        ResponsiveCard(label: 'Max Rating', value: stats.maxRating?.toString() ?? '0', icon: Icons.trending_up_rounded, color: Colors.orange),
        ResponsiveCard(label: 'Rank', value: stats.ranking ?? 'N/A', icon: Icons.workspace_premium_rounded, color: Colors.purple),
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

  Widget _buildPlatformMetricsGrid(PlatformStats stats, ThemeData theme) {
    final metrics = stats.extraMetrics;
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.2,
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
