// lib/widgets/insight/contest_readiness_card.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContestReadinessCard extends StatelessWidget {
  final int score;
  final Map<String, int> subScores; // Consistency, Breadth, Mix, Recent
  final String? upcomingContest;
  final DateTime? upcomingContestTime;

  const ContestReadinessCard({
    super.key,
    required this.score,
    required this.subScores,
    this.upcomingContest,
    this.upcomingContestTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String label;
    Color color;
    if (score >= 91) {      label = "Contest-ready"; color = Colors.green;
    } else if (score >= 71) { label = "Ready";         color = Colors.lightGreen;
    } else if (score >= 41) { label = "Getting there"; color = Colors.amber;
    } else {                  label = "Not ready";     color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Contest Readiness Score",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          CircularPercentIndicator(
            radius: 70.0,
            lineWidth: 12.0,
            percent: score / 100,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$score",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                ),
                Text(
                  "/ 100",
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ],
            ),
            footer: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: color,
            backgroundColor: color.withOpacity(0.1),
            animation: true,
            animationDuration: 1500,
          ),
          const SizedBox(height: 32),
          _buildScoreGrid(context),
          if (upcomingContest != null) ...[
            const SizedBox(height: 24),
            _buildContestRow(context),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildScoreGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildSubScore(context, "Consistency", subScores["Consistency"] ?? 0),
            _buildSubScore(context, "Topic Breadth", subScores["Breadth"] ?? 0),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSubScore(context, "Difficulty Mix", subScores["Mix"] ?? 0),
            _buildSubScore(context, "Recent Activity", subScores["Recent"] ?? 0),
          ],
        ),
      ],
    );
  }

  Widget _buildSubScore(BuildContext context, String label, int value) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("$value", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("/25", style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 25,
              minHeight: 3,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestRow(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Next Contest", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(
                  upcomingContest!, 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (upcomingContestTime != null)
            Text(
              "${upcomingContestTime!.day}/${upcomingContestTime!.month}",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
        ],
      ),
    ).animate().shimmer(delay: 2.seconds, duration: 2.seconds);
  }
}
