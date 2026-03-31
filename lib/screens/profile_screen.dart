import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import 'edit_profile_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';
import '../widgets/platform_card.dart';
import '../models/user_platform_data.dart';
import '../widgets/animations/fade_slide_transition.dart';
import '../widgets/premium_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final stats = context.watch<StatsProvider>();
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
                    Expanded(
                      child: Text(
                        'Account Settings',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                style: const TextStyle(
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

              _buildPlatformGrid(context, profile, stats),

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
                        onTap: () => Navigator.pushNamed(context, '/settings'),
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
                  onPressed: () => _showLogoutConfirmation(context),
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

  Widget _buildPlatformGrid(BuildContext context, ProfileProvider profile, StatsProvider stats) {
    final List<UserPlatformData> platforms = [
      UserPlatformData(
        platformName: 'LeetCode',
        username: (profile.profile?["leetcode"]?.isNotEmpty == true) ? profile.profile!["leetcode"]! : 'Not Connected',
        solvedCount: stats.leetcodeStats?.totalSolved ?? 0,
        rating: stats.leetcodeStats?.contestRating?.toInt(),
        ranking: stats.leetcodeStats?.ranking.toString(),
        isConnected: profile.profile?["leetcode"]?.isNotEmpty ?? false,
        icon: FontAwesomeIcons.code,
        color: AppTheme.leetCodeYellow,
      ),
      UserPlatformData(
        platformName: 'Codeforces',
        username: (profile.profile?["codeforces"]?.isNotEmpty == true) ? profile.profile!["codeforces"]! : 'Not Connected',
        solvedCount: stats.codeforcesStats?.totalSolved ?? 0,
        rating: stats.codeforcesStats?.rating,
        ranking: stats.codeforcesStats?.ranking,
        isConnected: profile.profile?["codeforces"]?.isNotEmpty ?? false,
        icon: FontAwesomeIcons.bolt,
        color: AppTheme.primary,
      ),
      UserPlatformData(
        platformName: 'CodeChef',
        username: (profile.profile?["codechef"]?.isNotEmpty == true) ? profile.profile!["codechef"]! : 'Not Connected',
        solvedCount: stats.codechefStats?.totalSolved ?? 0,
        rating: stats.codechefStats?.rating,
        ranking: stats.codechefStats?.ranking,
        isConnected: profile.profile?["codechef"]?.isNotEmpty ?? false,
        icon: FontAwesomeIcons.graduationCap,
        color: const Color(0xFF5B4638),
      ),
      UserPlatformData(
        platformName: 'GitHub',
        username: (profile.profile?["github"]?.isNotEmpty == true) ? profile.profile!["github"]! : 'Not Connected',
        solvedCount: stats.githubCommitCalendar.values.fold(0, (a, b) => a + b),
        isConnected: profile.profile?["github"]?.isNotEmpty ?? false,
        icon: FontAwesomeIcons.github,
        color: AppTheme.githubGrey,
      ),
      UserPlatformData(
        platformName: 'HackerRank',
        username: (profile.profile?["hackerrank"]?.isNotEmpty == true) ? profile.profile!["hackerrank"]! : 'Not Connected',
        solvedCount: stats.hackerrankStats?.totalSolved ?? 0,
        isConnected: profile.profile?["hackerrank"]?.isNotEmpty ?? false,
        icon: FontAwesomeIcons.hackerrank,
        color: const Color(0xFF2EC866),
      ),
    ];

    return FadeSlideTransition(
      delay: const Duration(milliseconds: 250),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: platforms.length,
        itemBuilder: (context, index) {
          return PlatformCard(data: platforms[index]);
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Deactivate Session",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text(
          "Are you sure you want to logout? All local cache will be cleared.",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: AppTheme.textSecondaryDark.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final statsProvider = context.read<StatsProvider>();
              final profileProvider = context.read<ProfileProvider>();
              
              Navigator.pop(context); // Close dialog
              
              // Logout using providers directly
              await authProvider.logout(
                statsProvider: statsProvider, 
                profileProvider: profileProvider
              );
              
              if (context.mounted) {
                // Safely return to root (AuthWrapper)
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Logout"),
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
