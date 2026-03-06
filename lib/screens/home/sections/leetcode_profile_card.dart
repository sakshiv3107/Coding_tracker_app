import 'package:flutter/material.dart';
import '../../../providers/stats_provider.dart';

class LeetCodeProfileCard extends StatelessWidget {
  final StatsProvider stats;

  const LeetCodeProfileCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats.leetcodeStats;

    if (data == null) {
      return const SizedBox();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.deepPurple,
              backgroundImage: NetworkImage(data.avatar),
            ),

            const SizedBox(width: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "LeetCode Ranking",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                Text(
                  "#${data.ranking}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Spacer(),

            const Icon(
              Icons.emoji_events,
              color: Colors.amber,
              size: 32,
            ),
          ],
        )
      ),
    );
  }
}