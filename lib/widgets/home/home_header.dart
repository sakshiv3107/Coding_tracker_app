import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/auth_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    return "Good night";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final statsProvider = Provider.of<StatsProvider>(context);
    final gamificationProvider = Provider.of<GamificationProvider>(context);

    final username = authProvider.user?['name'] ?? 'Coder';
    final greeting = _getGreeting();
    final streak = statsProvider.streakCount;
    final level = gamificationProvider.level;
    final xpProgress = gamificationProvider.progress;
    final currentXP = gamificationProvider.currentXP;

    final primaryPurple = const Color(0xFF7B68EE);
    final accentAmber = const Color(0xFFEF9F27);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$greeting, $username!",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.displayLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Keep up the grind",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            _buildStreakBadge(context, streak, accentAmber),
          ],
        ),
        const SizedBox(height: 20),
        _buildXPProgressBar(context, level, xpProgress, currentXP, primaryPurple),
      ],
    );
  }

  Widget _buildStreakBadge(BuildContext context, int streak, Color accentColor) {
    if (streak == 0) {
      return Text(
        "Start your streak",
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.grey.shade500,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accentColor, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department, // Using Material Icon as SVG placeholder if not available
            size: 16,
            color: Color(0xFFEF9F27),
          ),
          const SizedBox(width: 4),
          Text(
            "$streak day streak",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgressBar(
    BuildContext context,
    int level,
    double progress,
    int totalXP,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: primaryColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Level $level  ·  ${totalXP % 100}/100 XP",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
