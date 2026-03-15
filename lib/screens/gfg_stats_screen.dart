import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/platform_stats_details.dart';

class GfgStatsScreen extends StatelessWidget {
  const GfgStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final profile = context.watch<ProfileProvider>();
    final username = profile.profile?["gfg"] ?? "";

    return PlatformStatsDetailsScreen(
      stats: stats.gfgStats,
      platformName: "GeeksforGeeks",
      icon: Icons.school_rounded,
      color: Colors.green,
      username: username,
      isLoading: stats.isLoading,
      errorMessage: stats.error,
      onRefresh: () {
        if (username.isNotEmpty) {
          stats.fetchGfgStats(username);
        }
      },
    );
  }
}
