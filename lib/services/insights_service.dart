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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final int solvedToday = statsProvider.leetcodeStats?.submissionCalendar[today] ?? 0;

    // Calculate weekly progress (sum of last 7 days)
    int weeklySolved = 0;
    for (int i = 0; i < 7; i++) {
        final d = today.subtract(Duration(days: i));
        weeklySolved += statsProvider.leetcodeStats?.submissionCalendar[d] ?? 0;
    }

    final int totalSolved = statsProvider.totalSolved;
    final int leetcodeSolved = statsProvider.leetcodeStats?.totalSolved ?? 0;
    final int codeforcesSolved = statsProvider.codeforcesStats?.totalSolved ?? 0;
    final int githubCommits = statsProvider.githubCommitCalendar.values
        .fold(0, (a, b) => a + b);
    final int streak = statsProvider.leetcodeStats?.streak ?? 0;

    final Map<String, dynamic> userData = {
      'totalSolved': totalSolved,
      'solvedToday': solvedToday,
      'weeklySolved': weeklySolved,
      'leetcodeSolved': leetcodeSolved,
      'difficulty': {
        'easy': statsProvider.leetcodeStats?.easy ?? 0,
        'medium': statsProvider.leetcodeStats?.medium ?? 0,
        'hard': statsProvider.leetcodeStats?.hard ?? 0,
      },
      'codeforcesSolved': codeforcesSolved,
      'githubCommits': githubCommits,
      'streak': streak,
      'developerScore': statsProvider.developerScore?.score ?? 0,
      'developerLevel': statsProvider.developerScore?.level ?? 'Beginner',
      'topics': statsProvider.topicStrengths,
      'goalProgress': goalProvider.goals.map((g) {
        final progress = ProgressService.calculateProgress(
          goal: g,
          statsProvider: statsProvider,
          githubProvider: githubProvider,
        );
        return {
          'title': g.title,
          'currentValue': progress,
          'targetValue': g.targetValue,
          'progress': '${(progress / g.targetValue * 100).clamp(0, 100).toInt()}%',
          'isCompleted': progress >= g.targetValue,
        };
      }).toList(),
    };

    debugPrint('[InsightsService] Sending to AI → totalSolved=$totalSolved, '
        'difficulty=${userData['difficulty']}, '
        'github=$githubCommits, streak=$streak');

    // AIService already handles failure gracefully and returns dynamic fallback
    final insights = await AIService.generateInsights(userData: userData);
    debugPrint('[InsightsService] Got ${insights.length} insights: $insights');
    return insights;
  }
}
