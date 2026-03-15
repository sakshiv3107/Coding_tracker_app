import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isGuiMode = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    
    final userName = auth.user?["name"] ?? "Developer";
    final leetcodeUser = profile.profile?["leetcode"] ?? "not_set";

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          // ── Header / Profile Section ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.person_rounded, color: AppTheme.primary, size: 30),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '@$leetcodeUser',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Navigation Items ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                _buildDrawerItem(
                  context,
                  title: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/'); // Or however you handle home
                  },
                  isActive: true,
                ),
                _buildDrawerItem(
                  context,
                  title: 'Projects',
                  icon: Icons.folder_rounded,
                  onTap: () {},
                ),
                
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    'PLATFORMS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey,
                    ),
                  ),
                ),
                
                _buildDrawerItem(
                  context,
                  title: 'LeetCode',
                  icon: FontAwesomeIcons.code,
                  iconSize: 18,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/leetcode_stats');
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'CodeChef',
                  icon: Icons.restaurant_menu_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/codechef_stats');
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'Codeforces',
                  icon: Icons.trending_up_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/codeforces_stats');
                  },
                ),
                _buildDrawerItem(
                  context,
                  title: 'GeeksforGeeks',
                  icon: Icons.school_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/gfg_stats');
                  },
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
                ),
                
                const Divider(height: 32, indent: 16, endIndent: 16),
                
                _buildDrawerItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
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

          // ── Footer / Toggle Section ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _isGuiMode ? Icons.auto_awesome_rounded : Icons.terminal_rounded,
                      size: 20,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'GUI Mode',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: _isGuiMode,
                  activeColor: AppTheme.primary,
                  onChanged: (val) {
                    setState(() => _isGuiMode = val);
                  },
                ),
              ],
            ),
          ),
        ],
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
            ? AppTheme.primary.withValues(alpha: isDark ? 0.15 : 0.08) 
            : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(
          icon,
          size: iconSize,
          color: color ?? (isActive ? AppTheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? (isActive ? AppTheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
