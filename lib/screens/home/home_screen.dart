import 'package:coding_tracker_app/providers/github_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/stats_provider.dart';
import '../profile_screen.dart';
import '../coding_stats_screen.dart';
import '../github_stats_screen.dart';
import 'sections/welcome_section.dart';
import '../../screens/home/sections/platform_section.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<ProfileProvider>();
      final statsProvider = context.read<StatsProvider>();
      final githubProvider = context.read<GithubProvider>();
      
      final leetcodeUser = profile.profile?["leetcode"] ?? "";
      final githubUser = profile.profile?["github"] ?? "";

      if (leetcodeUser.isNotEmpty) {
        statsProvider.fetchLeetCodeStats(leetcodeUser);
      }
      if (githubUser.isNotEmpty) {
        githubProvider.fetchGithubData(githubUser);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<ProfileProvider>();
    // final stats = context.watch<StatsProvider>();
    final auth = context.read<AuthProvider>();
    final userName = auth.user?["name"] ?? "User";

    final screens = [
      _buildDashboard(userName: userName, theme: theme, profile: profile),
      const CodingStatsScreen(),
      const GitHubStatsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppTheme.primaryMint,
              unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.4),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'HOME'),
                BottomNavigationBarItem(icon: Icon(Icons.code_rounded), label: 'PLATFORMS'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'STATS'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard({
    required String userName,
    required ThemeData theme,
    required ProfileProvider profile,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          WelcomeSection(userName: userName, theme: theme, isSmallScreen: true),
          const SizedBox(height: 32),
          
          // Row of stats cards (Solved, Streak, Rank)
          Row(
            children: [
              Expanded(child: _buildMiniStatCard('SOLVED', '1,248', AppTheme.primaryMint)),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStatCard('STREAK', '42d', Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildMiniStatCard('RANK', 'Top 1%', Colors.blue)),
            ],
          ),
          
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Connected Platforms', style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {},
                child: const Text('View all', style: TextStyle(color: AppTheme.primaryMint)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PlatformSection(profile: profile, isSmallScreen: true),
          
          const SizedBox(height: 32),
          Text('Weekly Progress', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildWeeklyProgressChart(theme),
          const SizedBox(height: 100), // Space for bottom nav
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart(ThemeData theme) {
    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WEEKLY PROGRESS', style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.2)),
              const Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: AppTheme.primaryMint),
                  SizedBox(width: 8),
                  CircleAvatar(radius: 4, backgroundColor: Colors.grey),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(0.3, 'MON'),
                _buildBar(0.6, 'TUE'),
                _buildBar(0.2, 'WED'),
                _buildBar(0.8, 'THU'),
                _buildBar(1.0, 'FRI'),
                _buildBar(0.4, 'SAT'),
                _buildBar(0.3, 'SUN'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: AppTheme.primaryMint.withOpacity(heightFactor.clamp(0.2, 1.0)),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}
