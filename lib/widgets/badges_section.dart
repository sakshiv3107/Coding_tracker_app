import 'package:flutter/material.dart';
import '../models/leetcode_stats.dart';
import '../widgets/modern_card.dart';

class BadgesSection extends StatelessWidget {
  final List<LeetCodeBadge> badges;

  const BadgesSection({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('Badges', style: Theme.of(context).textTheme.titleLarge),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return ModernCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Expanded(
                    child: Image.network(
                      badge.icon,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  if (badge.earnedDate != null)
                    Text(
                      badge.earnedDate!,
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
