import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/premium_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userName = auth.user?["name"] ?? "Standard Developer";
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
                    Text(
                      'Account Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        );
                      },
                      icon: const Icon(FontAwesomeIcons.penToSquare, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
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
                child: ModernCard(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                  isGlass: true,
                  child: Center(
                    child: Column(
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.primary, AppTheme.accent],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primary,
                                  letterSpacing: -1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          userName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryDark.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const PremiumSectionHeader(
                title: 'Data Nodes',
                subtitle: 'Manage your connected platforms',
                icon: FontAwesomeIcons.networkWired,
              ),
              const SizedBox(height: 16),

              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: _PlatformTileSmall(
                  icon: FontAwesomeIcons.code,
                  platform: 'LeetCode',
                  username: profile.profile?["leetcode"] ?? "Node Inactive",
                  color: AppTheme.leetCodeYellow,
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: _PlatformTileSmall(
                  icon: FontAwesomeIcons.github,
                  platform: 'GitHub',
                  username: profile.profile?["github"] ?? "Node Inactive",
                  color: AppTheme.githubGrey,
                ),
              ),

              const SizedBox(height: 40),
              
              const PremiumSectionHeader(
                title: 'Configuration',
                subtitle: 'Personalize your experience',
                icon: FontAwesomeIcons.sliders,
              ),
              const SizedBox(height: 16),
              
              FadeSlideTransition(
                delay: const Duration(milliseconds: 450),
                child: ModernCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  isGlass: true,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: FontAwesomeIcons.bell,
                        title: 'Notifications',
                        subtitle: 'Alert nodes and sync cycles',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 48, color: Colors.white10),
                      _SettingsTile(
                        icon: FontAwesomeIcons.shieldHalved,
                        title: 'Privacy & Security',
                        subtitle: 'Multi-factor and key management',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 48, color: Colors.white10),
                      _SettingsTile(
                        icon: FontAwesomeIcons.circleQuestion,
                        title: 'Help & Knowledge Base',
                        subtitle: 'Documentation and support',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              FadeSlideTransition(
                delay: const Duration(milliseconds: 500),
                child: PremiumGradientButton(
                  text: 'Deactivate Session',
                  onPressed: () {
                    context.read<AuthProvider>().logout();
                    context.read<ProfileProvider>().clearProfile();
                  },
                  icon: FontAwesomeIcons.powerOff,
                  gradient: const [Colors.redAccent, Color(0xFF991B1B)],
                ),
              ),
              
              const SizedBox(height: 120),
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
    final theme = Theme.of(context);
    final isInactive = username == "Node Inactive";

    return ModernCard(
      padding: const EdgeInsets.all(18),
      isGlass: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FaIcon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform, 
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)
                ),
                Text(
                  username,
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark.withValues(alpha: 0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isInactive ? FontAwesomeIcons.circleExclamation : FontAwesomeIcons.solidCircleCheck, 
            color: isInactive ? Colors.orange.withValues(alpha: 0.5) : AppTheme.secondary, 
            size: 16
          ),
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
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)
      ),
      subtitle: Text(
        subtitle, 
        style: TextStyle(
          color: AppTheme.textSecondaryDark.withValues(alpha: 0.4), 
          fontSize: 12,
          fontWeight: FontWeight.w600,
        )
      ),
      trailing: Icon(
        FontAwesomeIcons.chevronRight, 
        size: 12, 
        color: AppTheme.textSecondaryDark.withValues(alpha: 0.2)
      ),
      onTap: onTap,
    );
  }
}
