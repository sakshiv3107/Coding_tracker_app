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

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text(
                'Upcoming Contests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                final isToday = contest.startTime.day == DateTime.now().day;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: contest.platform == 'Codeforces' 
                            ? Colors.red.withOpacity(0.1) 
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        contest.platform,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: contest.platform == 'Codeforces' ? Colors.red : Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contest.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, hh:mm a').format(contest.startTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
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
