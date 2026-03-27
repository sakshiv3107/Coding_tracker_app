import 'package:flutter/material.dart';
import '../services/contest_service.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ContestTrackerCard extends StatelessWidget {
  final List<Contest> contests;
  final bool isLoading;

  const ContestTrackerCard({
    super.key,
    required this.contests,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.event_note_rounded,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'Upcoming Contests',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/contests'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (contests.isEmpty && !isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No upcoming contests found.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contests.length > 5 ? 5 : contests.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final contest = contests[index];

                final Color platformColor;
                switch (contest.platform.toLowerCase()) {
                  case 'codeforces':
                    platformColor = Colors.redAccent;
                    break;
                  case 'leetcode':
                    platformColor = AppTheme.leetCodeYellow;
                    break;
                  case 'codechef':
                    platformColor = const Color(0xFFE08D2D);
                    break;
                  default:
                    platformColor = Colors.blueAccent;
                }

                return Row(
                  children: [
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: platformColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: platformColor.withOpacity(0.25), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          contest.platform,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: platformColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contest.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, hh:mm a')
                                .format(contest.startTime),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (contest.startsSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.flash_on_rounded,
                            size: 12, color: Colors.amber),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
