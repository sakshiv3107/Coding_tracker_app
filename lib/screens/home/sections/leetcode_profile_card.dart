import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

class LeetCodeProfileCard extends StatelessWidget {
  final StatsProvider stats;

  const LeetCodeProfileCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final data = stats.leetcodeStats;
    final theme = Theme.of(context);
    final auth = context.read<AuthProvider>();
    final userName = auth.user?["name"] ?? "Standard User";

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
            backgroundImage: data.avatar.isNotEmpty ? NetworkImage(data.avatar) : null,
            child: data.avatar.isEmpty ? const Icon(Icons.person, color: AppTheme.primaryMint) : null,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMintLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data.rating > 2000 ? 'KNIGHT' : 'ELITE',
                      style: const TextStyle(
                        color: AppTheme.primaryMint,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMiniStat(Icons.emoji_events_outlined, data.rating.toStringAsFixed(0)),
                  const SizedBox(width: 16),
                  _buildMiniStat(Icons.public_rounded, "Rank #${data.ranking}"),
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