import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import '../../theme/app_theme.dart';
import '../glass_card.dart';
import '../../providers/stats_provider.dart';

class ContestCountdownCard extends StatefulWidget {
  final List<dynamic>? contests;

  const ContestCountdownCard({super.key, this.contests});

  @override
  State<ContestCountdownCard> createState() => _ContestCountdownCardState();
}

class _ContestCountdownCardState extends State<ContestCountdownCard> {
  Timer? _timer;
  // final Map<String, bool> _reminded = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Started";
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);

    if (h > 0) {
      return "${h}h ${m}m ${s}s";
    }
    return "${m}m ${s}s";
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<StatsProvider>(context);
    final contests = widget.contests ?? statsProvider.upcomingContests;

    if (contests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              final timeRemaining = contest.startTime.difference(DateTime.now());
              final theme = Theme.of(context);
              // final isDark = theme.brightness == Brightness.dark;

              Color platformColor;
              IconData platformIcon;
              switch (contest.platform.toLowerCase()) {
                case 'leetcode':
                  platformColor = const Color(0xFFFFA116);
                  platformIcon = Icons.code_rounded;
                  break;
                case 'codeforces':
                  platformColor = const Color(0xFF318CE7);
                  platformIcon = Icons.trending_up_rounded;
                  break;
                case 'codechef':
                  platformColor = const Color(0xFF5B4638);
                  platformIcon = Icons.restaurant_menu_rounded;
                  break;
                default:
                  platformColor = theme.colorScheme.primary;
                  platformIcon = Icons.event_available_rounded;
              }

              return GlassCard(
                width: 240,
                height: 120,
                margin: const EdgeInsets.only(right: 16, bottom: 8),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: platformColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: platformColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(platformIcon, size: 12, color: platformColor),
                              const SizedBox(width: 2),
                              Text(
                                contest.platform,
                                style: TextStyle(
                                  color: platformColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (timeRemaining.inHours < 24 && !timeRemaining.isNegative)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    //const Spacer(),
                    const SizedBox(height: 15),
                    Text(
                      contest.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: timeRemaining.inHours < 12 
                            ? Colors.redAccent 
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDuration(timeRemaining),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: timeRemaining.inHours < 12 
                              ? Colors.redAccent 
                              : platformColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
