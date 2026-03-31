import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  /// Index of the currently active Home page (0=Dashboard, 3=Goals, 4=Profile).
  /// Null when the drawer is used outside HomeScreen (e.g. detail screens).
  final int? selectedIndex;

  /// Switches the active page inside HomeScreen. Called for pages 0, 3, 4.
  final void Function(int index)? onNavigate;

  const AppDrawer({
    super.key,
    this.selectedIndex,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final userName = auth.user?['name'] ?? 'Developer';
    final leetcodeUser = profile.profile?['leetcode'] ?? '';
    final profilePic = profile.profile?['profilePic'];

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
          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(context, userName, leetcodeUser, profilePic, isDark),

          // ── Scrollable Menu ──────────────────────────────────────────────
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              children: [
                // ── ANALYTICS HUB ──────────────────────────────────────────
                _sectionLabel('ANALYTICS HUB'),
                _pageItem(
                  context,
                  title: 'Control Center',
                  icon: Icons.dashboard_rounded,
                  pageIndex: 0,
                  isDark: isDark,
                ),
                _pushItem(
                  context,
                  title: 'Contest Calendar',
                  icon: Icons.calendar_today_rounded,
                  route: '/contests',
                  isDark: isDark,
                ),
                _pushItem(
                  context,
                  title: 'Career Dashboard',
                  icon: Icons.description_rounded,
                  route: '/resume',
                  isDark: isDark,
                ),
                _pageItem(
                  context,
                  title: 'Goals & Targets',
                  icon: Icons.flag_rounded,
                  pageIndex: 3,
                  isDark: isDark,
                ),

                const SizedBox(height: 24),
                // ── CONNECTED PLATFORMS ─────────────────────────────────────
                _sectionLabel('CONNECTED PLATFORMS'),
                _pushItem(
                  context,
                  title: 'LeetCode',
                  icon: FontAwesomeIcons.code,
                  route: '/leetcode_stats',
                  isDark: isDark,
                  iconSize: 16,
                ),
                _pushItem(
                  context,
                  title: 'GitHub',
                  icon: FontAwesomeIcons.github,
                  route: '/github_stats',
                  isDark: isDark,
                  iconSize: 18,
                ),
                _pushItem(
                  context,
                  title: 'HackerRank',
                  icon: FontAwesomeIcons.hackerrank,
                  route: '/hackerrank_stats',
                  isDark: isDark,
                  iconSize: 18,
                ),
                _pushItem(
                  context,
                  title: 'Codeforces',
                  icon: Icons.trending_up_rounded,
                  route: '/codeforces_stats',
                  isDark: isDark,
                ),
                _pushItem(
                  context,
                  title: 'CodeChef',
                  icon: Icons.restaurant_menu_rounded,
                  route: '/codechef_stats',
                  isDark: isDark,
                ),

                const SizedBox(height: 24),
                // ── ACCOUNT ─────────────────────────────────────────────────
                _sectionLabel('ACCOUNT'),
                _pageItem(
                  context,
                  title: 'Profile',
                  icon: Icons.person_rounded,
                  pageIndex: 4,
                  isDark: isDark,
                ),
                _pushItem(
                  context,
                  title: 'Settings',
                  icon: Icons.settings_rounded,
                  route: '/settings',
                  isDark: isDark,
                ),
                _actionItem(
                  context,
                  title: 'Sign Out',
                  icon: Icons.logout_rounded,
                  color: Colors.redAccent,
                  onTap: () {
                    // 1. Pop drawer
                    Navigator.pop(context);
                    // 2. Immediate navigation to root to let AuthWrapper handle the transition
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    // 3. Clear data
                    auth.logout(context);
                  },
                ),
              ],
            ),
          ),

          // ── Theme Toggle ─────────────────────────────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'v1.0.4 · CodeSphere',
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String name, String username,
      String? pic, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.only(topRight: Radius.circular(32)),
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
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: isDark
                      ? AppTheme.surfaceDarkLighter
                      : Colors.grey[200],
                  backgroundImage: (pic != null && pic.isNotEmpty)
                      ? NetworkImage(pic)
                      : null,
                    child: (pic == null || pic.isEmpty)
                        ? Icon(Icons.person_rounded,
                            color: theme.colorScheme.primary, 
                            size: 32)
                        : null,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DEV PRO',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
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
            username.isNotEmpty ? '@$username' : 'Setup your profile',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 10, top: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.8,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Page item — switches tab in HomeScreen without pushing a route.
  Widget _pageItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int pageIndex,
    required bool isDark,
    double iconSize = 22,
  }) {
    final isActive = selectedIndex == pageIndex;
    final theme = Theme.of(context);

    return _tile(
      context,
      title: title,
      icon: icon,
      iconSize: iconSize,
      isActive: isActive,
      isDark: isDark,
      theme: theme,
      onTap: () {
        if (onNavigate != null) {
          onNavigate!(pageIndex);
        } else {
          Navigator.pop(context);
        }
      },
    );
  }

  /// Push item — navigates to a named route.
  Widget _pushItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required bool isDark,
    double iconSize = 22,
  }) {
    final theme = Theme.of(context);
    final currentRoute =
        ModalRoute.of(context)?.settings.name ?? '/';
    final isActive = currentRoute == route;

    return _tile(
      context,
      title: title,
      icon: icon,
      iconSize: iconSize,
      isActive: isActive,
      isDark: isDark,
      theme: theme,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  /// Action item (e.g. logout) — no route, just a callback.
  Widget _actionItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, size: 22, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required double iconSize,
    required bool isActive,
    required bool isDark,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          icon,
          size: iconSize,
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.45),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.85),
            fontWeight:
                isActive ? FontWeight.w900 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
