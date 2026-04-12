import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stats_provider.dart';

class ContestCountdownCard extends StatefulWidget {
  final List<dynamic>? contests;

  const ContestCountdownCard({Key? key, this.contests}) : super(key: key);

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
              final timeRemaining = contest.startTime.difference(DateTime.now());
              // final isReminded = _reminded[contest.id] ?? false;

              return Container(
                width: 260, // Slightly narrower
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPlatformBadge(contest.platform),
                        Text(
                          DateFormat('MMM d, HH:mm').format(contest.startTime),
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      contest.title,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDuration(timeRemaining),
                      style: GoogleFonts.inter(
                        fontSize: 20, // Reduced from 24 to prevent overflow
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF7B68EE),
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

  Widget _buildPlatformBadge(String platform) {
    Color color = _getPlatformColor(platform);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        platform,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'leetcode': return const Color(0xFFEF9F27);
      case 'codeforces': return const Color(0xFFE24B4A);
      case 'codechef': return const Color(0xFF7B68EE);
      default: return Colors.grey;
    }
  }


}
