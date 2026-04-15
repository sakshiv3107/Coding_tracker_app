import '../models/goal.dart';
import '../providers/stats_provider.dart';
import '../providers/github_provider.dart';

class ProgressService {
  static int calculateProgress({
    required Goal goal,
    required StatsProvider statsProvider,
    required GithubProvider githubProvider,
  }) {
    final now = DateTime.now();

    if (goal.type == GoalType.commits) {
      if (githubProvider.githubStats == null) return 0;
      
      final calendar = githubProvider.githubStats!.contributionCalendar;
      if (goal.timeframe == GoalTimeframe.weekly) {
        int commits = 0;
        final int daysSinceMonday = now.weekday - 1;
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysSinceMonday));
        final today = DateTime(now.year, now.month, now.day);

        calendar.forEach((date, count) {
          final pureDate = DateTime(date.year, date.month, date.day);
          if ((pureDate.isAfter(startOfWeek) || pureDate.isAtSameMomentAs(startOfWeek)) && 
              (pureDate.isBefore(today) || pureDate.isAtSameMomentAs(today))) {
            commits += count;
          }
        });
        return commits;
      } else {
        // Daily commits
        final today = DateTime(now.year, now.month, now.day);
        int todayCommits = 0;
        calendar.forEach((date, count) {
          final pureDate = DateTime(date.year, date.month, date.day);
          if (pureDate.isAtSameMomentAs(today)) {
            todayCommits += count;
          }
        });
        return todayCommits;
      }
    } 

    if (goal.type == GoalType.questions) {
      int solved = 0;
      final today = DateTime(now.year, now.month, now.day);
      
      bool checkAll = goal.platform == null || goal.platform!.trim().isEmpty || goal.platform!.toLowerCase() == 'all';
      String targetPlatform = goal.platform?.toLowerCase() ?? '';

      DateTime startDate = today;
      if (goal.timeframe == GoalTimeframe.weekly) {
         final int daysSinceMonday = now.weekday - 1;
         startDate = today.subtract(Duration(days: daysSinceMonday));
      }

      // LeetCode
      if (checkAll || targetPlatform == 'leetcode') {
        final lcStats = statsProvider.leetcodeStats;
        if (lcStats != null) {
          int count = _getRangeCount(lcStats.submissionCalendar, startDate, today);
          // Only fallback to recent if the start date is today and range count is 0
          if (count == 0 && lcStats.recentSubmissions != null && startDate.isAtSameMomentAs(today)) {
            count = lcStats.recentSubmissions!.where((s) => s.status == 'Accepted' && _isToday(s.timestamp)).length;
          }
          solved += count;
        }
      }

      // Codeforces
      if (checkAll || targetPlatform == 'codeforces') {
        final cfStats = statsProvider.codeforcesStats;
        if (cfStats != null) {
          int count = _getRangeCount(cfStats.submissionCalendar, startDate, today);
          if (count == 0 && cfStats.recentSubmissions.isNotEmpty && startDate.isAtSameMomentAs(today)) {
            count = cfStats.recentSubmissions.where((s) => s.status == 'Accepted' && _isToday(s.timestamp)).length;
          }
          solved += count;
        }
      }

      // CodeChef
      if (checkAll || targetPlatform == 'codechef') {
        final ccStats = statsProvider.codechefStats;
        if (ccStats != null) {
          int count = _getRangeCount(ccStats.submissionCalendar, startDate, today);
          if (count == 0 && ccStats.recentSubmissions.isNotEmpty && startDate.isAtSameMomentAs(today)) {
            count = ccStats.recentSubmissions.where((s) => s.status == 'Accepted' && _isToday(s.timestamp)).length;
          }
          solved += count;
        }
      }

      return solved;
    }

    return 0;
  }

  static int _getRangeCount(Map<DateTime, int>? calendar, DateTime start, DateTime end) {
    if (calendar == null) return 0;
    int count = 0;
    calendar.forEach((key, value) {
      final pureDate = DateTime(key.year, key.month, key.day);
      if ((pureDate.isAfter(start) || pureDate.isAtSameMomentAs(start)) &&
          (pureDate.isBefore(end) || pureDate.isAtSameMomentAs(end))) {
        count += value;
      }
    });
    return count;
  }

  static bool _isToday(DateTime ts) {
    final now = DateTime.now();
    return ts.year == now.year && ts.month == now.month && ts.day == now.day;
  }
}


