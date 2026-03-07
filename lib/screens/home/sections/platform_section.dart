import 'package:coding_tracker_app/providers/stats_provider.dart';
import 'package:coding_tracker_app/providers/github_provider.dart';
import 'package:flutter/material.dart';
import '../../../providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/platform_card.dart';

class PlatformSection extends StatelessWidget {
  final ProfileProvider profile;
  final bool isSmallScreen;

  const PlatformSection({
    super.key,
    required this.profile,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();
    final platforms = [
      ('LeetCode', Icons.code, profile.profile?['leetcode'] ?? ''),
      ('GitHub', Icons.hub, profile.profile?['github'] ?? ''),
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: platforms.length,
      itemBuilder: (context, index) {
        final p = platforms[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PlatformCard(
            stats: stats,
            github: github,
            platform: p.$1,
            icon: p.$2,
            id: p.$3,
            isSmallScreen: isSmallScreen,
            isConnected: p.$3.isNotEmpty,
          ),
        );
      },
    );
  }
}
