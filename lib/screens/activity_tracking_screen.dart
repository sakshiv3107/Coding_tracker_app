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

  bool _isLoading = false;
  String? _error;

  Map<DateTime, int>? _githubData;
  Map<DateTime, int>? _leetcodeData;

  int _ghContribs = 0;
  int _lcSubmissions = 0;
  int _currentStreak = 0;
  int _maxStreak = 0;
  int _ghCurrentStreak = 0;
  int _ghMaxStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final profile = context.read<ProfileProvider>();
    final githubUser = profile.githubHandle;
    final leetcodeUser = profile.leetcodeHandle;

    setState(() => _isLoading = true);

    try {
      if (githubUser != null && githubUser.isNotEmpty) {
        final ghStats = await _githubService.fetchStats(githubUser);
        _githubData = ghStats.contributionCalendar;
        _ghContribs = ghStats.totalContributions;

        final ghStreaks = _calculateStreaks(_githubData ?? {});
        _ghCurrentStreak = ghStreaks['streak'] ?? 0;
        _ghMaxStreak = ghStreaks['longestStreak'] ?? 0;
      }

      if (leetcodeUser != null && leetcodeUser.isNotEmpty) {
        final lcStats = await _leetcodeService.fetchData(leetcodeUser);
        _leetcodeData = lcStats.submissionCalendar;
        _lcSubmissions = lcStats.totalSolved;
        _currentStreak = lcStats.streak;
        _maxStreak = lcStats.longestStreak;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, int> _calculateStreaks(Map<DateTime, int> calendar) {
    if (calendar.isEmpty) return {'streak': 0, 'longestStreak': 0};

    final sorted =
        calendar.keys.map((d) => DateTime(d.year, d.month, d.day)).toList()
          ..sort();

    int maxStreak = 0;
    int tempStreak = 0;
    if (sorted.isNotEmpty) {
      maxStreak = 1;
      tempStreak = 1;
      for (var i = 1; i < sorted.length; i++) {
        final diff = sorted[i].difference(sorted[i - 1]).inDays;
        if (diff == 1) {
          tempStreak++;
          if (tempStreak > maxStreak) maxStreak = tempStreak;
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yest = todayDate.subtract(const Duration(days: 1));

    int current = 0;
    if (calendar.containsKey(todayDate) || calendar.containsKey(yest)) {
      current = 1;
      var check = calendar.containsKey(todayDate) ? todayDate : yest;
      while (true) {
        check = check.subtract(const Duration(days: 1));
        if (calendar.containsKey(
          DateTime(check.year, check.month, check.day),
        )) {
          current++;
        } else {
          break;
        }
      }
    }

    return {'streak': current, 'longestStreak': maxStreak};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                        if (_isLoading)
                          _buildLoadingState()
                        else if (_error != null)
                          _buildErrorState()
                        else ...[
                          _buildStatsOverview(),
                          const SizedBox(height: 32),
                          if (_leetcodeData != null) ...[
                            _buildPlatformSection(
                              'LeetCode Analytics',
                              _leetcodeData!,
                              Colors.orange,
                              'Solved',
                              _lcSubmissions.toString(),
                              _currentStreak,
                              _maxStreak,
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (_githubData != null) ...[
                            _buildPlatformSection(
                              'GitHub Analytics',
                              _githubData!,
                              Colors.green,
                              'Commits',
                              _ghContribs.toString(),
                              _ghCurrentStreak,
                              _ghMaxStreak,
                            ),
                            const SizedBox(height: 32),
                          ],
                          if (_leetcodeData == null && _githubData == null)
                            _buildEmptyState(),
                        ],
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

  Widget _buildPlatformSection(
    String title,
    Map<DateTime, int> data,
    Color color,
    String primaryLabel,
    String primaryValue,
    int currentStreak,
    int maxStreak,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              color: theme.textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            _buildSmallStatCard(
              primaryLabel,
              primaryValue,
              Icons.analytics_rounded,
              color,
            ),
            const SizedBox(width: 10),
            _buildSmallStatCard(
              'Streak',
              '$currentStreak d',
              Icons.local_fire_department_rounded,
              Colors.orange,
            ),
            const SizedBox(width: 10),
            _buildSmallStatCard(
              'Max Streak',
              '$maxStreak d',
              Icons.workspace_premium_rounded,
              Colors.amber,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(isDark ? 0.02 : 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: ActivityHeatmap(
                data: data,
                baseColor: color,
                label: '',
                tooltipLabel: 'activities',
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildSmallStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(isDark ? 0.03 : 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color.withOpacity(0.8)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        _buildStatCard(
          'Total Active',
          (_ghContribs + _lcSubmissions).toString(),
          Icons.analytics_rounded,
          AppTheme.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Streak',
          '${_currentStreak > _ghCurrentStreak ? _currentStreak : _ghCurrentStreak} d',
          Icons.local_fire_department_rounded,
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Max Streak',
          '${_maxStreak > _ghMaxStreak ? _maxStreak : _ghMaxStreak} d',
          Icons.workspace_premium_rounded,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(isDark ? 0.04 : 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.link_off_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            'No Platforms Connected',
            style: GoogleFonts.outfit(
              color: theme.textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect your profiles in settings to see your activity reports.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const CircularProgressIndicator(color: AppTheme.primary),
          const SizedBox(height: 20),
          Text(
            'Compiling your activity report...',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20),
          Text(
            'Report generation failed',
            style: GoogleFonts.outfit(
              color: theme.textTheme.titleLarge?.color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.redAccent.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadAllData(),
            child: const Text('Retry Synchronize'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withOpacity(0.05),
            ),
          ).animate().scale(duration: 2.seconds, curve: Curves.easeInOut),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withOpacity(0.03),
            ),
          ).animate().scale(duration: 3.seconds, curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Text(
          'Activity Insights',
          style: GoogleFonts.outfit(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.iconTheme.color, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: theme.iconTheme.color),
          onPressed: _loadAllData,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
