import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../glass_card.dart';
import '../../providers/stats_provider.dart';

class StreakAlertBanner extends StatefulWidget {
  final VoidCallback onSolveNow;

  const StreakAlertBanner({super.key, required this.onSolveNow});

  @override
  State<StreakAlertBanner> createState() => _StreakAlertBannerState();
}

class _StreakAlertBannerState extends State<StreakAlertBanner> with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final statsProvider = Provider.of<StatsProvider>(context, listen: false);
    final now = DateTime.now();
    
    // Trigger logic
    final isLate = now.hour >= 20;
    
    final today = DateTime(now.year, now.month, now.day);
    final todaySolved = statsProvider.leetcodeStats?.submissionCalendar[today] ?? 0;
    final currentStreak = statsProvider.streakCount;

    if (!isLate || todaySolved > 0 || currentStreak == 0) {
      if (mounted) setState(() => _isVisible = false);
      return;
    }

    // Check dismissal
    final prefs = await SharedPreferences.getInstance();
    final dismissalKey = "streak_banner_dismissed_${DateFormat('yyyyMMdd').format(now)}";
    final isDismissed = prefs.getBool(dismissalKey) ?? false;

    if (!isDismissed && mounted) {
      setState(() => _isVisible = true);
      _animationController.forward();
    }
  }

  void _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissalKey = "streak_banner_dismissed_${DateFormat('yyyyMMdd').format(DateTime.now())}";
    await prefs.setBool(dismissalKey, true);
    
    _animationController.reverse().then((_) {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final statsProvider = Provider.of<StatsProvider>(context);
    final streak = statsProvider.streakCount;

    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 20,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkAccent
                      : AppTheme.lightAccent,
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.secondary
                      : AppTheme.lightAccentSecondary,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔥 $streak Day Streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Keep it going!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


