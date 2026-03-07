import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import 'home/sections/leetcode_profile_card.dart';
import 'home/sections/stats_section.dart';
import 'home/sections/difficulty_section.dart';
import 'home/sections/leetcode_pie_chart.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coding Stats'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            stats.error ?? "Error loading stats",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (stats.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                LeetCodeProfileCard(stats: stats),

                const SizedBox(height: 24),

                StatsSection(
                  stats: stats,
                  theme: theme,
                  isSmallScreen: isSmallScreen,
                ),

                const SizedBox(height: 24),

                DifficultySection(stats: stats),

                const SizedBox(height: 24),

                LeetCodePieChart(stats: stats),

                const SizedBox(height: 24),

                Center(
                  child: SizedBox(
                    width: isSmallScreen ? double.infinity : null,
                    child: FilledButton.icon(
                      onPressed: () {
                        final username = profile.profile?["leetcode"] ?? "";
                        if (username.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please set your LeetCode username in profile settings",
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }
                        context.read<StatsProvider>().fetchLeetCodeStats(
                          username,
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Stats'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 12,
                          horizontal: isSmallScreen ? 16 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
