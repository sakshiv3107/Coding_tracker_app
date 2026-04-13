import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEF9F27).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF9F27), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF9F27), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Streak ending soon",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF9F27),
                      ),
                    ),
                    Text(
                      "Solve 1 problem to keep your $streak-day streak",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onSolveNow,
                child: Text(
                  "Solve now →",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF9F27),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _dismiss,
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
