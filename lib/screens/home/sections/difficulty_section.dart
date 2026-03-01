import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/stats_provider.dart';
import '../widgets/difficulty_card.dart';

class DifficultySection extends StatelessWidget {
  final StatsProvider stats;

  const DifficultySection({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "LeetCode Stats",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),

        // 1️⃣ Loading State
        if (stats.isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )

        // 2️⃣ Error State
        else if (stats.error != null)
          Column(
            children: [
              const Text(
                "Failed to fetch stats ❌",
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<StatsProvider>()
                      .fetchLeetCodeStats("your_username_here");
                },
                child: const Text("Retry"),
              )
            ],
          )

        // 3️⃣ Empty State
        else if (stats.leetcodeStats == null)
          const Text(
            "Press Refresh to load stats",
            style: TextStyle(color: Colors.grey),
          )

        // 4️⃣ Success State
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              _buildDifficultySplit(context, isSmallScreen),
            ],
          ),
      ],
    );
  }

  Widget _buildDifficultySplit(BuildContext context, bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          DifficultyCard(
            title: 'Easy',
            value: stats.leetcodeStats?.easy.toString() ?? "-",
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          DifficultyCard(
            title: 'Medium',
            value: stats.leetcodeStats?.medium.toString() ?? "-",
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          DifficultyCard(
            title: 'Hard',
            value: stats.leetcodeStats?.hard.toString() ?? "-",
            color: Colors.red,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DifficultyCard(
            title: 'Easy',
            value: stats.leetcodeStats?.easy.toString() ?? "-",
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DifficultyCard(
            title: 'Medium',
            value: stats.leetcodeStats?.medium.toString() ?? "-",
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DifficultyCard(
            title: 'Hard',
            value: stats.leetcodeStats?.hard.toString() ?? "-",
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}