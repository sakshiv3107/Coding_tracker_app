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
import '../../widgets/app_drawer.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const CodingStatsScreen(),
    const GitHubStatsScreen(),
    const GoalsScreen(),
    const ProfileScreen(),
  ];

  String? _lastGhUser;
  String? _lastLcUser;

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
    final cfUser = profile.profile?["codeforces"] ?? "";
    final ccUser = profile.profile?["codechef"] ?? "";
    final gfgUser = profile.profile?["gfg"] ?? "";
    final hrUser = profile.profile?["hackerrank"] ?? "";

    stats.fetchAllStats(
      leetcode: lcUser,
      codeforces: cfUser,
      codechef: ccUser,
      gfg: gfgUser,
      hackerrank: hrUser,
    );
    
    if (ghUser.isNotEmpty) {
      github.fetchGithubData(ghUser).then((_) {
        if (github.githubStats != null) {
          stats.updateGitHubData(
            commitCalendar: github.githubStats!.contributionCalendar,
            stars: github.githubStats!.totalStars,
            totalCommits: github.githubStats!.totalContributions,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = context.watch<ProfileProvider>();
    
    // Auto-refresh if usernames changed (e.g. after editing profile)
    final lcUser = profile.profile?["leetcode"] ?? "";
    final ghUser = profile.profile?["github"] ?? "";
    
    if (lcUser != _lastLcUser || ghUser != _lastGhUser) {
      _lastLcUser = lcUser;
      _lastGhUser = ghUser;
      // Use microtask to avoid calling notifyListeners during build
      Future.microtask(() => _refreshAllData());
    }
    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

}
