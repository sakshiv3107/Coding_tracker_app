import 'package:flutter/material.dart';
import '../../../providers/profile_provider.dart';
import '../widgets/platform_card.dart';
import '../dialogs/edit_profile_dialog.dart';

class PlatformSection extends StatelessWidget {
  final ProfileProvider profile;
  final bool isSmallScreen;

  const PlatformSection({
    super.key,
    required this.profile,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final platforms = [
      ('LeetCode', Icons.code, profile.profile?['leetcode'] ?? ''),
      ('CodeChef', Icons.restaurant, profile.profile?['codechef'] ?? ''),
      ('CodeForces', Icons.bolt, profile.profile?['codeforces'] ?? ''),
      ('GitHub', Icons.hub, profile.profile?['github'] ?? ''),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coding Profiles',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton.filled(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const EditProfileDialog(),
                  );
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: isSmallScreen ? 2 : 4,
          crossAxisSpacing: isSmallScreen ? 12 : 16,
          mainAxisSpacing: isSmallScreen ? 12 : 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isSmallScreen ? 0.95 : 1.1,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: platforms
              .map(
                (platform) =>
                    _buildPlatformCard(platform.$1, platform.$2, platform.$3),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPlatformCard(String name, IconData icon, String username) {
    return PlatformCard(
      platform: name,
      icon: icon,
      id: username,
      isSmallScreen: isSmallScreen,
      isConnected: username.isNotEmpty,
    );
  }
}
