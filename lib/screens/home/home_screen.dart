// lib/screens/home/home_screen.dart
//
// FIX: Removed bottom NavigationBar, restored AppDrawer-based navigation.
// Pages switch via a callback passed to the drawer, avoiding bottom nav.

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

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const CodingStatsScreen();
      case 2:
        return const GitHubStatsScreen();
      case 3:
        return const GoalsScreen();
      case 4:
        return ProfileScreen(
          onBack: () {
            if (_selectedIndex != 0) {
              setState(() => _selectedIndex = 0);
            }
          },
        );
      default:
        return const DashboardScreen();
    }
  }

  void _navigateTo(int index) {
    Navigator.pop(context); // close drawer first to ensure smooth animation
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

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

  void _initializeData() {
    if (!mounted) return;
    final profile = context.read<ProfileProvider>();
    
    // If profile is null and not loading, we need to trigger initialization.
    // This happens if the user re-logged and the AuthWrapper was bypassed.
    if (profile.profile == null && !profile.isLoading) {
      profile.initializeProfile();
    }

    if (profile.isLoading) {
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
      if (mounted) _doFetch();
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

    // Show spinner ONLY while profile intentionally loads from network
    if (profile.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC))),
      );
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        // Drawer with page-switch callback
        drawer: AppDrawer(
          selectedIndex: _selectedIndex,
          onNavigate: _navigateTo,
        ),
        // Only the active page is built (no IndexedStack)
        body: _buildPage(_selectedIndex),
      ),
    );
  }
}


