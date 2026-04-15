import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Upcoming Contests",
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 154, // Slightly reduced height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final contest = contests[index];
              final timeRemaining = contest.startTime.difference(
                DateTime.now(),
              );
              // final isReminded = _reminded[contest.id] ?? false;

              return GlassCard(
                width: 260,
                margin: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.timer, color: AppTheme.warning),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contest.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Starts in ${_formatDuration(timeRemaining)}',
                            style: const TextStyle(color: AppTheme.warning),
                          ),
                        ],
                      ),
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
