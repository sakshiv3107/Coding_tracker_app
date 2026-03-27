import 'package:flutter/material.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: EdgeInsets.zero,
      showShadow: true,
      borderRadius: 28,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              FontAwesomeIcons.solidUserCircle,
              size: 100,
              color: AppTheme.primary.withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Premium Avatar Ring
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
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
                      Text(
                        name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leetcodeUser.isNotEmpty ? '@$leetcodeUser' : 'Setup Developer ID',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondaryDark.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _smallBadge(FontAwesomeIcons.cube, '$totalPlatforms Nodes', AppTheme.primary),
                          _smallBadge(FontAwesomeIcons.circleCheck, 'Verified', Colors.green),
                        ],
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w800, 
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
