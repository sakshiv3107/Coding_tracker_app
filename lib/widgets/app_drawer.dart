import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

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
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Drawer(
      backgroundColor: isDark ? AppTheme.bgDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // ── Premium Profile Header ─────────────────────────────────────
          _buildHeader(context, userName, leetcodeUser, profilePic, isDark),

          // ── Scrollable Menu ──────────────────────────────────────────
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                _buildSectionLabel('ANALYTICS HUB'),
                _buildMenuItem(
                  context,
                  title: 'Control Center',
                  icon: Icons.dashboard_rounded,
                  route: '/',
                  currentRoute: currentRoute,
                ),
                _buildMenuItem(
                  context,
                  title: 'Unified Insights',
                  icon: Icons.analytics_rounded,
                  route: '/analytics',
                  currentRoute: currentRoute,
                ),
                _buildMenuItem(
                  context,
                  title: 'Career Dashboard',
                  icon: Icons.description_rounded,
                  route: '/resume',
                  currentRoute: currentRoute,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('CONNECTED NODES'),
                _buildMenuItem(
                  context,
                  title: 'LeetCode',
                  icon: FontAwesomeIcons.code,
                  route: '/leetcode_stats',
                  currentRoute: currentRoute,
                  iconSize: 16,
                ),
                _buildMenuItem(
                  context,
                  title: 'GitHub',
                  icon: FontAwesomeIcons.github,
                  route: '/github_stats',
                  currentRoute: currentRoute,
                  iconSize: 18,
                ),
                _buildMenuItem(
                  context,
                  title: 'HackerRank',
                  icon: FontAwesomeIcons.hackerrank,
                  route: '/hackerrank_stats',
                  currentRoute: currentRoute,
                  iconSize: 18,
                ),
                _buildMenuItem(
                  context,
                  title: 'GeeksforGeeks',
                  icon: Icons.school_rounded,
                  route: '/gfg_stats',
                  currentRoute: currentRoute,
                ),
                _buildMenuItem(
                  context,
                  title: 'Codeforces',
                  icon: Icons.trending_up_rounded,
                  route: '/codeforces_stats',
                  currentRoute: currentRoute,
                ),
                _buildMenuItem(
                  context,
                  title: 'CodeChef',
                  icon: Icons.restaurant_menu_rounded,
                  route: '/codechef_stats',
                  currentRoute: currentRoute,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel('SYSTEM'),
                _buildMenuItem(
                  context,
                  title: 'Global Settings',
                  icon: Icons.settings_rounded,
                  route: '/settings',
                  currentRoute: currentRoute,
                ),
                _buildMenuItem(
                  context,
                  title: 'Terminate Session',
                  icon: Icons.logout_rounded,
                  color: Colors.redAccent,
                  currentRoute: currentRoute,
                  onTap: () {
                    Navigator.pop(context);
                    auth.logout();
                  },
                ),
              ],
            ),
          ),

          // ── Theme Toggle & Version ─────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THEME MODE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDark ? 'Dark Optimized' : 'Light Vibrant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: isDark,
                  activeColor: AppTheme.primary,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'v1.0.4 - ALPHA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: theme.colorScheme.onSurface.withOpacity(0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String username, String? pic, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(topRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'drawer_avatar',
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: isDark ? AppTheme.surfaceDarkLighter : Colors.grey[200],
                    backgroundImage: (pic != null && pic.isNotEmpty) ? NetworkImage(pic) : null,
                    child: (pic == null || pic.isEmpty)
                        ? const Icon(Icons.person_rounded, color: AppTheme.primary, size: 32)
                        : null,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DEV PRO',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@$username',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: AppTheme.primary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    String? route,
    required String currentRoute,
    double iconSize = 22,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isActive = route != null && currentRoute == route;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive 
            ? AppTheme.primary.withOpacity(isDark ? 0.15 : 0.08) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap ?? () {
          Navigator.pop(context);
          if (route != null && currentRoute != route) {
            if (route == '/') {
              Navigator.pushReplacementNamed(context, '/');
            } else {
              Navigator.pushNamed(context, route);
            }
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          icon,
          size: iconSize,
          color: color ?? (isActive ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? (isActive ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.8)),
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: isActive 
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              )
            : null,
      ),
    );
  }
}
