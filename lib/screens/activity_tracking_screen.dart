import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/github_service.dart';
import '../services/leetcode_service.dart';
import '../widgets/activity_heatmap.dart';
import '../theme/app_theme.dart';
import '../providers/profile_provider.dart';

class ActivityTrackingScreen extends StatefulWidget {
  const ActivityTrackingScreen({super.key});

  @override
  State<ActivityTrackingScreen> createState() => _ActivityTrackingScreenState();
}

class _ActivityTrackingScreenState extends State<ActivityTrackingScreen> {
  final _githubService = GithubService();
  final _leetcodeService = LeetcodeService();
  
  bool _isGithubSelected = true;
  bool _isLoading = false;
  String? _error;
  
  Map<DateTime, int>? _githubData;
  Map<DateTime, int>? _leetcodeData;
  
  int _totalContribs = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profile = context.read<ProfileProvider>();
    final githubUser = profile.githubHandle;
    final leetcodeUser = profile.leetcodeHandle;

    if (githubUser != null && githubUser.isNotEmpty) {
      _fetchGithubData(githubUser);
    } else if (leetcodeUser != null && leetcodeUser.isNotEmpty) {
      _fetchLeetcodeData(leetcodeUser);
      setState(() => _isGithubSelected = false);
    }
  }

  Future<void> _fetchGithubData(String username) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await _githubService.fetchStats(username);
      setState(() {
        _githubData = stats.contributionCalendar;
        _totalContribs = stats.totalContributions;
        // Basic streak calculation from map (assuming map keys are sorted)
        _calculateStreaks(_githubData!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLeetcodeData(String username) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stats = await _leetcodeService.fetchData(username);
      setState(() {
        _leetcodeData = stats.submissionCalendar;
        // Summing up all submissions in the calendar for total count
        _totalContribs = stats.submissionCalendar.values.fold(0, (sum, count) => sum + count); 
        _currentStreak = stats.streak;
        _maxStreak = stats.longestStreak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _calculateStreaks(Map<DateTime, int> calendar) {
    if (calendar.isEmpty) return;
    
    // Sort keys and normalize to date only
    final sortedDates = calendar.keys.where((d) => (calendar[d] ?? 0) > 0).toList()..sort();
    
    if (sortedDates.isEmpty) {
      setState(() {
        _currentStreak = 0;
        _maxStreak = 0;
      });
      return;
    }

    int current = 0;
    int max = 0;
    int temp = 1;

    for (int i = 1; i < sortedDates.length; i++) {
        if (sortedDates[i].difference(sortedDates[i-1]).inDays == 1) {
            temp++;
        } else {
            if (temp > max) max = temp;
            temp = 1;
        }
    }
    if (temp > max) max = temp;

    // Current streak
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yestDate = todayDate.subtract(const Duration(days: 1));
    
    int currentRun = 0;
    if (calendar[todayDate] != null && calendar[todayDate]! > 0 || calendar[yestDate] != null && calendar[yestDate]! > 0) {
        DateTime check = calendar[todayDate] != null && calendar[todayDate]! > 0 ? todayDate : yestDate;
        while (calendar[check] != null && calendar[check]! > 0) {
            currentRun++;
            check = check.subtract(const Duration(days: 1));
        }
    }

    setState(() {
        _maxStreak = max;
        _currentStreak = currentRun;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final currentUsername = _isGithubSelected ? profile.githubHandle : profile.leetcodeHandle;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlatformToggle(),
                        const SizedBox(height: 24),
                        if (currentUsername == null || currentUsername.isEmpty)
                          _buildEmptyState()
                        else if (_isLoading)
                          _buildLoadingState()
                        else if (_error != null)
                          _buildErrorState()
                        else
                          _buildHeatmapContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -50,
          child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: (_isGithubSelected ? Colors.green : Colors.orange).withOpacity(0.08), backgroundBlendMode: BlendMode.screen)).animate().shader(),
        ),
        Positioned(
          bottom: 100, left: -50,
          child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.05))),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
      ),
      centerTitle: true,
      title: Text('Activity Heatmap', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPlatformToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          _buildToggleItem('GitHub', _isGithubSelected, true),
          _buildToggleItem('LeetCode', !_isGithubSelected, false),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String label, bool isSelected, bool github) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isGithubSelected = github;
            _isLoading = false;
            _error = null;
          });
          final profile = context.read<ProfileProvider>();
          final user = github ? profile.githubHandle : profile.leetcodeHandle;
          if (user != null && user.isNotEmpty) {
            github ? _fetchGithubData(user) : _fetchLeetcodeData(user);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (github ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15)) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? (github ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)) : Colors.transparent),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(color: isSelected ? Colors.white : Colors.white.withOpacity(0.4), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.link_off_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            '${_isGithubSelected ? 'GitHub' : 'LeetCode'} not connected',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect your profile to see your activity heatmap.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 100),
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 20),
          Text('Syncing activity...', style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
          const SizedBox(height: 20),
          Text('Could not load activity', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
               final profile = context.read<ProfileProvider>();
               final user = _isGithubSelected ? profile.githubHandle : profile.leetcodeHandle;
               if (user != null) {
                  _isGithubSelected ? _fetchGithubData(user) : _fetchLeetcodeData(user);
               }
            },
            child: const Text('Try Again', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapContent() {
    final activityData = _isGithubSelected ? _githubData : _leetcodeData;
    if (activityData == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsRow(),
        const SizedBox(height: 32),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: ActivityHeatmap(
                data: activityData,
                baseColor: _isGithubSelected ? Colors.green : Colors.orange,
                label: _isGithubSelected ? 'GitHub Contributions' : 'LeetCode Submissions',
                tooltipLabel: _isGithubSelected ? 'contributions' : 'submissions',
              ),
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(_isGithubSelected ? 'Contribs' : 'Submissions', _totalContribs.toString(), Icons.analytics_rounded),
        const SizedBox(width: 12),
        _buildStatCard('Streak', '$_currentStreak d', Icons.local_fire_department_rounded),
        const SizedBox(width: 12),
        _buildStatCard('Max', '$_maxStreak d', Icons.workspace_premium_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: (_isGithubSelected ? Colors.green : Colors.orange).withOpacity(0.6)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
