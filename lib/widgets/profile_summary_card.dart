import 'package:flutter/material.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class ProfileSummaryCard extends StatelessWidget {
  final String name;
  final String leetcodeUser;
  final String githubUser;
  final int totalPlatforms;
  final String? profilePicUrl;

  const ProfileSummaryCard({
    super.key,
    required this.name,
    required this.leetcodeUser,
    required this.githubUser,
    required this.totalPlatforms,
    this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              backgroundImage: (profilePicUrl != null && profilePicUrl!.isNotEmpty) 
                  ? NetworkImage(profilePicUrl!) 
                  : null,
              child: (profilePicUrl == null || profilePicUrl!.isEmpty)
                  ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 40)
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  leetcodeUser.isNotEmpty ? '@$leetcodeUser' : 'Setup Profile',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _smallBadge(Icons.hub_rounded, '$totalPlatforms Platforms', Colors.indigo),
                    _smallBadge(Icons.verified_user_rounded, 'Verified', Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
