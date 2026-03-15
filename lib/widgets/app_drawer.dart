import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    
    final userName = auth.user?["name"] ?? "Developer";
    final leetcodeUser = profile.profile?["leetcode"] ?? "not_set";
    final profilePic = profile.profile?["profilePic"];

    return Drawer(
      backgroundColor: isDark ? AppTheme.bgDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // ── Profile Section (Top) ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary,
                  AppTheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'drawer_avatar',
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      backgroundImage: (profilePic != null && profilePic.isNotEmpty) 
                          ? NetworkImage(profilePic) 
                          : null,
                      child: (profilePic == null || profilePic.isEmpty)
                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 36)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@$leetcodeUser',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                // ── Navigation Section ─────────────────────────────────────
                _buildSectionHeader('NAVIGATION'),
                _buildDrawerItem(
                  context,
                  title: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    if (ModalRoute.of(context)?.settings.name != '/') {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/',
                ),
                _buildDrawerItem(
                  context,
                  title: 'Projects',
                  icon: Icons.folder_special_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/github_stats');
                  },
                ),

                const SizedBox(height: 24),
                
                // ── Platforms Section ──────────────────────────────────────
                _buildSectionHeader('PLATFORMS'),
                _buildDrawerItem(
                  context,
                  title: 'LeetCode',
                  icon: FontAwesomeIcons.code,
                  iconSize: 18,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/leetcode_stats');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/leetcode_stats',
                ),
                _buildDrawerItem(
                  context,
                  title: 'Codeforces',
                  icon: Icons.trending_up_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/codeforces_stats');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/codeforces_stats',
                ),
                _buildDrawerItem(
                  context,
                  title: 'CodeChef',
                  icon: Icons.restaurant_menu_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/codechef_stats');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/codechef_stats',
                ),
                _buildDrawerItem(
                  context,
                  title: 'GeeksforGeeks',
                  icon: Icons.school_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/gfg_stats');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/gfg_stats',
                ),
                _buildDrawerItem(
                  context,
                  title: 'GitHub',
                  icon: FontAwesomeIcons.github,
                  iconSize: 18,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/github_stats');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/github_stats',
                ),
                _buildDrawerItem(
                  context,
                  title: 'HackerRank',
                  icon: FontAwesomeIcons.hackerrank,
                  iconSize: 18,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/hackerrank_stats');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/hackerrank_stats',
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 48),
                ),

                _buildDrawerItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                  isActive: ModalRoute.of(context)?.settings.name == '/settings',
                ),
                _buildDrawerItem(
                  context,
                  title: 'Logout',
                  icon: Icons.logout_rounded,
                  color: Colors.redAccent,
                  onTap: () {
                    context.read<AuthProvider>().logout();
                  },
                ),
              ],
            ),
          ),

          // ── Footer / Theme Toggle ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Theme',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isDark,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    double iconSize = 21,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isActive 
            ? AppTheme.primary.withOpacity(isDark ? 0.15 : 0.08) 
            : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          size: iconSize,
          color: color ?? (isActive ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? (isActive ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.8)),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
