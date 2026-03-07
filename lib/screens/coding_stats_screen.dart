import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import 'home/sections/leetcode_profile_card.dart';
import 'home/sections/stats_section.dart';
import 'home/sections/difficulty_section.dart';
import 'home/sections/leetcode_pie_chart.dart';
import '../theme/app_theme.dart';

class CodingStatsScreen extends StatefulWidget {
  const CodingStatsScreen({super.key,});

  @override
  State<CodingStatsScreen> createState() => _CodingStatsScreenState();
}

class _CodingStatsScreenState extends State<CodingStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>();
      final statsProvider = context.read<StatsProvider>();
      final username = profile.profile?["leetcode"] ?? "";

      if (username.isNotEmpty) {
        statsProvider.fetchLeetCodeStats(username);
      } else {
        statsProvider.setError("LeetCode username not set in profile");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.charcoal),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text('LeetCode', style: theme.textTheme.headlineMedium),
                  const Spacer(),
                  const Icon(Icons.verified_rounded, color: AppTheme.primaryMint, size: 24),
                ],
              ),
              const SizedBox(height: 32),

              if (stats.error != null)
                _buildErrorBanner(stats.error!, () {
                  final username = profile.profile?["leetcode"] ?? "";
                  if (username.isNotEmpty) {
                    context.read<StatsProvider>().fetchLeetCodeStats(username);
                  }
                })
              else if (stats.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primaryMint),
                  ),
                )
              else ...[
                LeetCodeProfileCard(stats: stats),
                const SizedBox(height: 32),
                StatsSection(stats: stats, theme: theme, isSmallScreen: true),
                const SizedBox(height: 32),
                DifficultySection(stats: stats),
                const SizedBox(height: 32),
                LeetCodePieChart(stats: stats),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    final username = profile.profile?["leetcode"] ?? "";
                    if (username.isNotEmpty) {
                      context.read<StatsProvider>().fetchLeetCodeStats(username);
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh Data'),
                ),
                const SizedBox(height: 100),
              ],
            ],
          ),
        ),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded, color: AppTheme.errorRed, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.charcoal.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.charcoal.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                elevation: 0,
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
