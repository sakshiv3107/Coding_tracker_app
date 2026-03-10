import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    final userName = auth.user?["name"] ?? "Developer";
    final userEmail = auth.user?["email"] ?? "developer@codesphere.com";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeSlideTransition(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile', style: theme.textTheme.headlineMedium),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      },
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // User Profile Section
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(userName, style: theme.textTheme.titleLarge?.copyWith(fontSize: 24)),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: Text('Connected Platforms', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 16),

              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: _PlatformTileSmall(
                  icon: FontAwesomeIcons.code,
                  platform: 'LeetCode',
                  username: profile.profile?["leetcode"] ?? "Not set",
                  color: AppTheme.leetCodeYellow,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: _PlatformTileSmall(
                  icon: FontAwesomeIcons.github,
                  platform: 'GitHub',
                  username: profile.profile?["github"] ?? "Not set",
                  color: AppTheme.githubBlack,
                ),
              ),

              const SizedBox(height: 40),
              
              FadeSlideTransition(
                delay: const Duration(milliseconds: 400),
                child: Text('App Settings', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 16),
              
              FadeSlideTransition(
                delay: const Duration(milliseconds: 450),
                child: ModernCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  showShadow: true,
                  showBorder: false,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Manage your alerts',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 48),
                      _SettingsTile(
                        icon: Icons.security_rounded,
                        title: 'Privacy & Security',
                        subtitle: 'Change your password',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 48),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        subtitle: 'Get assistance',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FadeSlideTransition(
                delay: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      context.read<ProfileProvider>().clearProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                    ),
                    child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformTileSmall extends StatelessWidget {
  final IconData icon;
  final String platform;
  final String username;
  final Color color;

  const _PlatformTileSmall({
    required this.icon,
    required this.platform,
    required this.username,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isGitHub = platform == 'GitHub';
    return ModernCard(
      padding: const EdgeInsets.all(16),
      showShadow: true,
      showBorder: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: isGitHub && Theme.of(context).brightness == Brightness.dark ? Colors.white : color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(platform, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  username,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 18),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}
