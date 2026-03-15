import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/platform_stats_details.dart';

class HackerRankStatsScreen extends StatelessWidget {
  const HackerRankStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final profile = context.watch<ProfileProvider>();
    final username = profile.profile?["hackerrank"] ?? "";

    // Since we don't have a HackerRank service yet, we could use a mock or just show empty for now.
    // Let's assume some mock data if stats are null
    
    return PlatformStatsDetailsScreen(
      stats: null, // Placeholder or implement a service similar to others
      platformName: "HackerRank",
      icon: Icons.code_rounded, // FontAwesomeIcons.hackerrank if imported
      color: Colors.greenAccent.shade700,
      username: username,
      isLoading: false,
      onRefresh: () {
        // Implement HackerRank fetch if needed
      },
    );
  }
}
