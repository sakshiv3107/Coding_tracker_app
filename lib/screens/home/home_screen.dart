// lib/screens/home/home_screen.dart
//
// FIX: Replaced IndexedStack with a simple body switcher.
// IndexedStack builds ALL pages simultaneously (even hidden ones) causing
// FadeSlideTransition and other animated widgets in those pages to crash
// with "Null check operator" / "RenderBox was not laid out" errors before
// their constraints are established. Now only the active page is built.

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
  int _selectedIndex = 0;

  String? _lastLcUser;
  String? _lastGhUser;
  String? _lastCfUser;
  String? _lastCcUser;
  String? _lastHrUser;

  bool _initialFetchDone = false;

  // Pages list — built lazily (only current index is rendered)
  static const List<Widget> _pages = [
    DashboardScreen(),
    CodingStatsScreen(),
    GitHubStatsScreen(),
    GoalsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialFetchDone) return;

    final profile = context.read<ProfileProvider>();
    final lcUser = profile.profile?['leetcode'] ?? '';
    final ghUser = profile.profile?['github'] ?? '';
    final cfUser = profile.profile?['codeforces'] ?? '';
    final ccUser = profile.profile?['codechef'] ?? '';
    final hrUser = profile.profile?['hackerrank'] ?? '';

    final changed = lcUser != _lastLcUser ||
        ghUser != _lastGhUser ||
        cfUser != _lastCfUser ||
        ccUser != _lastCcUser ||
        hrUser != _lastHrUser;

    if (changed) {
      _lastLcUser = lcUser;
      _lastGhUser = ghUser;
      _lastCfUser = cfUser;
      _lastCcUser = ccUser;
      _lastHrUser = hrUser;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshAllData(forceRefresh: true);
      });
    }
  }

  // ── Data initialisation ──────────────────────────────────────────────────

  void _initializeData() {
    if (!mounted) return;
    final profile = context.read<ProfileProvider>();

    if (profile.isLoading || profile.profile == null) {
      profile.addListener(_onProfileReady);
      return;
    }

    _doFetch();
  }

  void _onProfileReady() {
    if (!mounted) return;
    final profile = context.read<ProfileProvider>();
    if (!profile.isLoading) {
      profile.removeListener(_onProfileReady);
      if (profile.profile != null) {
        _doFetch();
      }
    }
  }

  void _doFetch() {
    if (!mounted) return;

    final profile = context.read<ProfileProvider>();
    final stats = context.read<StatsProvider>();
    final github = context.read<GithubProvider>();

    final lcUser = profile.profile?['leetcode'] ?? '';
    final ghUser = profile.profile?['github'] ?? '';
    final cfUser = profile.profile?['codeforces'] ?? '';
    final ccUser = profile.profile?['codechef'] ?? '';
    final hrUser = profile.profile?['hackerrank'] ?? '';

    _lastLcUser = lcUser;
    _lastGhUser = ghUser;
    _lastCfUser = cfUser;
    _lastCcUser = ccUser;
    _lastHrUser = hrUser;
    _initialFetchDone = true;

    stats.initializeAndFetch(
      leetcode: lcUser,
      codeforces: cfUser,
      codechef: ccUser,
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

  void _refreshAllData({bool forceRefresh = false}) {
    if (!mounted) return;

    final profile = context.read<ProfileProvider>();
    final stats = context.read<StatsProvider>();
    final github = context.read<GithubProvider>();

    final lcUser = profile.profile?['leetcode'] ?? '';
    final ghUser = profile.profile?['github'] ?? '';
    final cfUser = profile.profile?['codeforces'] ?? '';
    final ccUser = profile.profile?['codechef'] ?? '';
    final hrUser = profile.profile?['hackerrank'] ?? '';

    stats.fetchAllStats(
      leetcode: lcUser,
      codeforces: cfUser,
      codechef: ccUser,
      hackerrank: hrUser,
      forceRefresh: forceRefresh,
    );

    if (ghUser.isNotEmpty) {
      github.fetchGithubData(ghUser, forceRefresh: forceRefresh).then((_) {
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
  void dispose() {
    try {
      context.read<ProfileProvider>().removeListener(_onProfileReady);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    // Show spinner while profile loads
    if (profile.isLoading || profile.profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(),
      // KEY FIX: Use _pages[_selectedIndex] instead of IndexedStack.
      // This ensures only the active page's widget tree is built.
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.code_rounded),
            label: 'LeetCode',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_rounded),
            label: 'GitHub',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_rounded),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}