import 'package:flutter/material.dart';
import '../../../providers/stats_provider.dart';
// import '../../../widgets/modern_card.dart';
import '../../../theme/app_theme.dart';

class LeetCodeProfileCard extends StatelessWidget {
  final StatsProvider stats;

  const LeetCodeProfileCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats.leetcodeStats;
    final theme = Theme.of(context);

    if (data == null) return const SizedBox();

    return Row(
      children: [
        // Premium Avatar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryMint, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryMint.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryMintLight,
            backgroundImage: NetworkImage(data.avatar),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Alex Rivera", // This should probably come from Auth, but for mockup accuracy
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                "Mastering technical interviews",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMiniStat(Icons.emoji_events_outlined, "2,140"),
                  const SizedBox(width: 16),
                  _buildMiniStat(Icons.public_rounded, "Top 5.2%"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryMint),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.charcoal),
        ),
      ],
    );
  }
}