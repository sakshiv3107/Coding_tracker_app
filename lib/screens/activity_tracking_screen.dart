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
      }

      if (leetcodeUser != null && leetcodeUser.isNotEmpty) {
        final lcStats = await _leetcodeService.fetchData(leetcodeUser);
        _leetcodeData = lcStats.submissionCalendar;
        _lcSubmissions = lcStats.submissionCalendar.values.fold(0, (sum, count) => sum + count);
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

  @override
  Widget build(BuildContext context) {
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
                        if (_isLoading)
                          _buildLoadingState()
                        else if (_error != null)
                          _buildErrorState()
                        else ...[
                          _buildStatsOverview(),
                          const SizedBox(height: 32),
                          if (_leetcodeData != null) ...[
                            _buildHeatmapSection('LeetCode Submissions', _leetcodeData!, Colors.orange),
                            const SizedBox(height: 24),
                          ],
                          if (_githubData != null) ...[
                            _buildHeatmapSection('GitHub Contributions', _githubData!, Colors.green),
                            const SizedBox(height: 24),
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

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -50,
          child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.08))),
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
      title: Text('Activity Report', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      pinned: true,
    );
  }

  Widget _buildStatsOverview() {
    return Row(
      children: [
        _buildStatCard('Total Active', (_ghContribs + _lcSubmissions).toString(), Icons.analytics_rounded, AppTheme.primary),
        const SizedBox(width: 12),
        _buildStatCard('Streak', '$_currentStreak d', Icons.local_fire_department_rounded, Colors.orange),
        const SizedBox(width: 12),
        _buildStatCard('Max Streak', '$_maxStreak d', Icons.workspace_premium_rounded, Colors.amber),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapSection(String title, Map<DateTime, int> data, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
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

  Widget _buildEmptyState() {
     return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.link_off_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 20),
          Text(
            'No Platforms Connected',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect your profiles in settings to see your activity reports.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 100),
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 20),
          Text('Compiling your activity report...', style: TextStyle(color: Colors.white, fontSize: 14)),
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
          Text('Report generation failed', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadAllData(),
            child: const Text('Retry Synchronize'),
          ),
        ],
      ),
    );
  }
}
