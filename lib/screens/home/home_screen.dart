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
      final username = profile.profile?["leetcode"] ?? "";

      if (username.isNotEmpty) {
        statsProvider.fetchLeetCodeStats(username);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    final userName = auth.user?["name"] ?? "User";
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    late Widget currentPage;

    switch (_selectedIndex) {
      case 0:
        currentPage = _buildDashboard(
          userName: userName,
          theme: theme,
          profile: profile,
          isSmallScreen: isSmallScreen,
        );
        break;
      case 1:
        currentPage = const CodingStatsScreen();
        break;
      case 2:
        currentPage = const GitHubStatsScreen();
        break;
      case 3:
        currentPage = const ProfileScreen();
        break;
      default:
        currentPage = _buildDashboard(
          userName: userName,
          theme: theme,
          profile: profile,
          isSmallScreen: isSmallScreen,
        );
    }

    return Scaffold(
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.code),
            label: 'Coding',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'GitHub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard({
    required String userName,
    required ThemeData theme,
    required ProfileProvider profile,
    required bool isSmallScreen,
  }) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CodeSphere'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeSection(
                userName: userName,
                theme: theme,
                isSmallScreen: isSmallScreen,
              ),

              const SizedBox(height: 24),

              PlatformSection(profile: profile, isSmallScreen: isSmallScreen),

              const SizedBox(height: 24),

              // Quick Links to Other Sections
              Text(
                'Quick Access',
                style: theme.textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _QuickAccessCard(
                      icon: Icons.code,
                      title: 'Coding Stats',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessCard(
                      icon: Icons.pets,
                      title: 'GitHub',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 2;
                        });
                      },
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    _QuickAccessCard(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Getting Started',
                style: theme.textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              _InfoCard(
                icon: Icons.info_outline,
                title: 'View Your Coding Stats',
                description: 'Check your LeetCode progress, difficulty breakdown, and achievements',
                color: Colors.purple,
              ),

              const SizedBox(height: 12),

              _InfoCard(
                icon: Icons.pets,
                title: 'GitHub Integration',
                description: 'Link your GitHub profile to see your contributions and repositories',
                color: Colors.black87,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
