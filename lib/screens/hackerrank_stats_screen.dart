import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/hackerrank_stats.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/not_connected_widget.dart';

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
      appBar: AppBar(
        title: const Text('HackerRank Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshStats,
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
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    child: _buildProfileHeader(stats),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: FadeSlideTransition(
                    delay: const Duration(milliseconds: 100),
                    child: _buildMainStats(stats),
                  ),
                ),
              ),
            ] else if (statsProvider.hackerrankError != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text("Connection Error", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text(
                          statsProvider.hackerrankError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _refreshStats,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: const Text("Try Again"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Fallback for when data is null but no error yet
              const SliverFillRemaining(
                child: Center(child: Text("No data available")),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(HackerRankStats stats) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.green.withOpacity(0.1),
            backgroundImage: (stats.avatarUrl != null && stats.avatarUrl!.isNotEmpty) ? NetworkImage(stats.avatarUrl!) : null,
            child: (stats.avatarUrl == null || stats.avatarUrl!.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.green) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'HackerRank Developer ${stats.country != null ? "• ${stats.country}" : ""}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(HackerRankStats stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _statCard('Solved', stats.totalSolved.toString(), Icons.check_circle_outline, Colors.green),
        _statCard('Rank', stats.rank ?? 'N/A', Icons.trending_up, Colors.blue),
        _statCard('Badges', stats.extraMetrics["badges_count"]?.toString() ?? '0', Icons.badge, Colors.orange),
        _statCard('Country', stats.country ?? 'N/A', Icons.public, Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
