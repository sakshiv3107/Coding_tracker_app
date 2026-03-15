import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/platform_stats_details.dart';

class CodeforcesStatsScreen extends StatelessWidget {
  const CodeforcesStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final profile = context.watch<ProfileProvider>();
    final username = profile.profile?["codeforces"] ?? "";

    return PlatformStatsDetailsScreen(
      stats: stats.codeforcesStats,
      platformName: "Codeforces",
      icon: Icons.trending_up_rounded,
      color: Colors.blueAccent,
      username: username,
      isLoading: stats.codeforcesLoading,
      errorMessage: stats.codeforcesError,
      onRefresh: () {
        if (username.isNotEmpty) {
          stats.fetchCodeforcesStats(username);
        }
      },
    );
  }
}
