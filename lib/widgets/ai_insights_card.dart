import 'package:flutter/material.dart';
import 'modern_card.dart';
import '../theme/app_theme.dart';

class AIInsightsCard extends StatelessWidget {
  final int leetcodeSolved;
  final int githubCommits;
  final Map<String, int> tagStats;
  final int easy;
  final int medium;
  final int hard;
  final String? recommendation;

  const AIInsightsCard({
    super.key,
    required this.leetcodeSolved,
    required this.githubCommits,
    required this.tagStats,
    required this.easy,
    required this.medium,
    required this.hard,
    this.recommendation,
  });

  List<String> _generateInsights() {
    List<String> insights = [];
    if (recommendation != null) {
      insights.add(recommendation!);
    }

    // Analyze difficulty
    if (medium > easy && medium > hard) {
      insights.add("You solve mostly Medium difficulty problems. Great for building core intuition!");
    } else if (hard > medium) {
      insights.add("Impressive! Your hard problem count is high. You're tackling complex logic.");
    } else if (easy > medium) {
      insights.add("Building consistency with Easy problems! Consider trying more Medium ones to level up.");
    }

    // Analyze GitHub
    if (githubCommits > 50) {
      insights.add("Strong development activity this month with $githubCommits commits!");
    }

    // Suggested focus based on tag stats (rule-based)
    // Find missing or low areas
    final basicTags = ['Arrays', 'Strings', 'Hash Table'];
    final advancedTags = ['Dynamic Programming', 'Graphs', 'Trees'];
    
    String? focus;
    for (var tag in advancedTags) {
      if ((tagStats[tag] ?? 0) < 5) {
        focus = tag;
        break;
      }
    }
    
    if (focus != null) {
      insights.add("Suggested focus: Tackle more $focus problems to strengthen your algorithm repertoire.");
    } else {
      insights.add("Solid coverage across advanced topics. Keep exploring new contest problems!");
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insights = _generateInsights();

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.purple, size: 24),
              ),
              const SizedBox(width: 14),
              const Text(
                'AI Coding Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (insights.isEmpty)
            const Text("Keep coding to unlock more personalized insights!"),
        ],
      ),
    );
  }
}
