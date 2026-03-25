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

  // Track last-known usernames to detect changes
  String? _lastLcUser;
  String? _lastGhUser;
  // Guard against re-entrant refresh during the first-load lifecycle
  bool _initialRefreshDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialRefreshDone = true;
      _refreshAllData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only run after the initial post-frame refresh has been scheduled
    if (!_initialRefreshDone) return;

    final profile = context.read<ProfileProvider>();
    final lcUser = profile.profile?["leetcode"] ?? "";
    final ghUser = profile.profile?["github"] ?? "";

    // Only refresh when usernames actually change (e.g. after edit-profile)
    if (lcUser != _lastLcUser || ghUser != _lastGhUser) {
      _lastLcUser = lcUser;
      _lastGhUser = ghUser;
      // Schedule outside of the current build/dependency phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshAllData();
      });
    }
  }

  void _refreshAllData() {
    if (!mounted) return;
    final profile = context.read<ProfileProvider>();
    final stats = context.read<StatsProvider>();
    final github = context.read<GithubProvider>();

    final lcUser = profile.profile?["leetcode"] ?? "";
    final ghUser = profile.profile?["github"] ?? "";
    final cfUser = profile.profile?["codeforces"] ?? "";
    final ccUser = profile.profile?["codechef"] ?? "";
    final gfgUser = profile.profile?["gfg"] ?? "";
    final hrUser = profile.profile?["hackerrank"] ?? "";

    // Cache current usernames
    _lastLcUser = lcUser;
    _lastGhUser = ghUser;

    stats.fetchAllStats(
      leetcode: lcUser,
      codeforces: cfUser,
      codechef: ccUser,
      gfg: gfgUser,
      hackerrank: hrUser,
    );

    if (ghUser.isNotEmpty) {
      github.fetchGithubData(ghUser).then((_) {
        if (!mounted) return;
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
    return Scaffold(
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
    );
  }

}
