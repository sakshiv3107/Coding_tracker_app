import 'package:coding_tracker_app/providers/stats_provider.dart';
import 'package:coding_tracker_app/providers/goal_provider.dart';
import 'package:coding_tracker_app/providers/github_provider.dart';
import 'package:coding_tracker_app/services/ai_service.dart';
import 'package:coding_tracker_app/services/progress_service.dart';
import 'package:flutter/foundation.dart';

class InsightsService {
  static Future<List<String>> fetchDynamicInsights(
    StatsProvider statsProvider,
    GoalProvider goalProvider,
    GithubProvider githubProvider,
  ) async {
    try {
      final Map<String, dynamic> userData = {
        'totalSolved': statsProvider.totalSolved,
        'leetcodeSolved': statsProvider.leetcodeStats?.totalSolved ?? 0,
        'codeforcesSolved': statsProvider.codeforcesStats?.totalSolved ?? 0,
        'githubCommits': statsProvider.githubCommitCalendar.values.fold(0, (a, b) => a + b),
        'goalProgress': goalProvider.goals.map((g) {
          final progress = ProgressService.calculateProgress(
            goal: g,
            statsProvider: statsProvider,
            githubProvider: githubProvider,
          );
          return {
            'title': g.title,
            'progress': '${(progress / g.targetValue * 100).toInt()}%',
            'isCompleted': progress >= g.targetValue,
          };
        }).toList(),
        'streak': statsProvider.leetcodeStats?.streak ?? 0,
        'developerScore': statsProvider.developerScore?.score ?? 0,
        'developerLevel': statsProvider.developerScore?.level ?? 'Beginner',
        'topics': statsProvider.topicStrengths,
      };

      // Call AI Service
      final insights = await AIService.generateInsights(userData: userData);
      return insights;
    } catch (e) {
      debugPrint('InsightsService Error: $e');
      return ['Stay consistent and keep coding! 🔥', 'Keep pushing towards your goals! 🚀'];
    }
  }
}
