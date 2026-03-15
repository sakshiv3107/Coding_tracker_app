import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/github_provider.dart';
import '../profile_screen.dart';
import '../leetcode_stats_screen.dart';
import '../github_stats_screen.dart';
import '../dashboard_screen.dart';
import '../goals_screen.dart';
import '../../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const CodingStatsScreen(),
    const GitHubStatsScreen(),
    const GoalsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  void _refreshAllData() {
    final profile = context.read<ProfileProvider>();
    final stats = context.read<StatsProvider>();
    final github = context.read<GithubProvider>();

    final lcUser = profile.profile?["leetcode"] ?? "";
    final ghUser = profile.profile?["github"] ?? "";

    if (lcUser.isNotEmpty) stats.fetchLeetCodeStats(lcUser);
    if (ghUser.isNotEmpty) github.fetchGithubData(ghUser);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Home'),
                _buildNavItem(1, FontAwesomeIcons.code, 'LeetCode'),
                _buildNavItem(2, FontAwesomeIcons.github, 'GitHub'),
                _buildNavItem(3, Icons.track_changes_rounded, 'Goals'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final color = isSelected ? AppTheme.primary : Colors.grey.shade500;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
