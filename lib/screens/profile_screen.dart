import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/stats_provider.dart';
import 'edit_profile_screen.dart';
import '../theme/app_theme.dart';
// import '../widgets/modern_card.dart';
import '../widgets/platform_card.dart';
import '../models/user_platform_data.dart';
import '../widgets/premium_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/glassmorphic_container.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

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
      body: Stack(
        children: [
          // ── Background Blobs ───────────────────────────────────────────
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(20, 20), duration: 12.seconds),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.tertiary.withOpacity(0.04),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .move(begin: const Offset(0, 0), end: const Offset(-20, -20), duration: 10.seconds),
          ),

          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBackButton(context, isDark),
                  const SizedBox(width: 20),
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
                    icon: const FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.1),
              const SizedBox(height: 32),

              // User Profile Section
              GlassmorphicContainer(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                borderRadius: 32,
                child: Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: isDark ? AppTheme.darkSecondaryBg : Colors.white,
                            backgroundImage: (profile.profile?["profilePic"]?.isNotEmpty == true)
                                ? CachedNetworkImageProvider(profile.profile!["profilePic"]!)
                                : null,
                            child: (profile.profile?["profilePic"]?.isNotEmpty != true)
                                ? Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'D',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: -1,
                                    ),
                                  )
                                : null,
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
                          color: AppTheme.darkTextSecondary.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
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
              
              GlassmorphicContainer(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                borderRadius: 28,
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
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 48),

              PremiumGradientButton(
                text: 'Deactivate Session',
                onPressed: () => _showLogoutConfirmation(context),
                icon: FontAwesomeIcons.powerOff,
                gradient: const [Colors.redAccent, Color(0xFF991B1B)],
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),]
    ));
  }
  Widget _buildBackButton(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);
    if (!canPop && onBack == null) {
      return const SizedBox(width: 40, height: 40); // Placeholder to maintain layout balance
    }
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSecondaryBg : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () {
          if (onBack != null) {
            onBack!();
          } else if (canPop) {
            Navigator.pop(context);
          }
        },
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: theme.colorScheme.onSurface,
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

    return GridView.builder(
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
        return PlatformCard(data: platforms[index])
            .animate().fadeIn(delay: (200 + index * 100).ms).scale();
      },
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
              style: TextStyle(color: AppTheme.darkTextSecondary.withOpacity(0.6)),
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
  final dynamic icon;
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
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: icon is IconData 
            ? Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18)
            : FaIcon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      ),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.2)
      ),
      subtitle: Text(
        subtitle, 
        style: TextStyle(
          color: AppTheme.darkTextSecondary.withOpacity(0.4), 
          fontSize: 12,
          fontWeight: FontWeight.w600,
        )
      ),
      trailing: const FaIcon(
        FontAwesomeIcons.chevronRight, 
        size: 12, 
        color: Colors.grey
      ),
      onTap: onTap,
    );
  }
}


