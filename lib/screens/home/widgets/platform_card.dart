import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/modern_card.dart';
import '../../../providers/stats_provider.dart';

class PlatformCard extends StatelessWidget {
  final String platform;
  final StatsProvider stats;
  final IconData icon;
  final String id;
  final bool isSmallScreen;
  final bool isConnected;

  const PlatformCard({
    super.key,
    required this.stats,
    required this.platform,
    required this.icon,
    required this.id,
    required this.isSmallScreen,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnected ? AppTheme.primaryMintLight : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isConnected ? AppTheme.primaryMint : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      isConnected ? '@$id' : 'Not Connected',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: 20),
            Text(
              platform == 'LeetCode' ? 'CONTEST RATING' : 'CONTRIBUTIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              platform == 'LeetCode' ? stats.leetcodeStats?.rating.toString() ?? '24' : '2,412',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF457B6C),
              ),
            ),
          ] else ...[
            const SizedBox(height: 20),
            Text(
              'Click to link account',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }
}