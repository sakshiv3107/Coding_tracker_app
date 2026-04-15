import 'package:flutter/material.dart';
import '../models/leetcode_stats.dart';
import '../widgets/glass_card.dart';

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
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              Text('Badges & Achievements', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return InkWell(
              onTap: () => _showBadgeDetails(context, badge),
              borderRadius: BorderRadius.circular(24),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: badge.icon.startsWith('http') 
                          ? Image.network(
                              badge.icon,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
                            )
                          : const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      badge.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    if (badge.earnedDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        badge.earnedDate!,
                        style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showBadgeDetails(BuildContext context, LeetCodeBadge badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: badge.icon.startsWith('http') 
                ? Image.network(badge.icon) 
                : const Icon(Icons.stars_rounded, color: Colors.amber),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(badge.name, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge.description != null && badge.description!.isNotEmpty) ...[
              Text(
                badge.description!,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
            if (badge.earnedDate != null)
              Text(
                'Earned on: ${badge.earnedDate}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}



