// lib/widgets/insight/contest_readiness_card.dart
import 'package:flutter/material.dart';
// import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ContestReadinessCard extends StatelessWidget {
  final int score;
  final Map<String, int> subScores; // Consistency, Breadth, Mix, Recent
  final String? verdict;
  final String? upcomingContest;
  final DateTime? upcomingContestTime;

  const ContestReadinessCard({
    super.key,
    required this.score,
    required this.subScores,
    this.verdict,
    this.upcomingContest,
    this.upcomingContestTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String label;
    Color color;
    if (score >= 91) {      label = "Elite Ready"; color = Colors.green;
    } else if (score >= 71) { label = "Ready";         color = Colors.lightGreen;
    } else if (score >= 41) { label = "Building";      color = Colors.amber;
    } else {                  label = "Preparation";   color = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header / Score Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contest Readiness',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score of $score/100 • $label',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50, height: 50,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    Text('$score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          
          // Verdict Section (Efficient highlight)
          if (verdict != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      verdict!,
                      style: const TextStyle(fontSize: 11, height: 1.4, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Sub-scores (Simplified into a row)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Consistency', subScores['Consistency'] ?? 0),
                _buildStatItem('Breadth', subScores['Breadth'] ?? 0),
                _buildStatItem('Mix', subScores['Mix'] ?? 0),
                _buildStatItem('Recent', subScores['Recent'] ?? 0),
              ],
            ),
          ),
          
          if (upcomingContest != null) 
            _buildContestRow(context),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
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


