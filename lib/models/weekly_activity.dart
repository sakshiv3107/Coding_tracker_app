// models/weekly_activity.dart

class DailyActivity {
  final DateTime date;
  final int leetcodeSubmissions;
  final int githubCommits;

  DailyActivity({
    required this.date,
    required this.leetcodeSubmissions,
    required this.githubCommits,
  });

  int get total => leetcodeSubmissions + githubCommits;
}

class WeeklyActivity {
  final List<DailyActivity> days;

  WeeklyActivity({required this.days});

  factory WeeklyActivity.fromData({
    required Map<DateTime, int> leetcodeCalendar,
    required Map<DateTime, int> githubCalendar,
  }) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final days = List.generate(7, (i) {
      final date = DateTime(monday.year, monday.month, monday.day + i);
      final normalized = DateTime(date.year, date.month, date.day);
      return DailyActivity(
        date: date,
        leetcodeSubmissions: leetcodeCalendar[normalized] ?? 0,
        githubCommits: githubCalendar[normalized] ?? 0,
      );
    });

    return WeeklyActivity(days: days);
  }

  int get maxActivity =>
      days.map((d) => d.total).reduce((a, b) => a > b ? a : b);
}