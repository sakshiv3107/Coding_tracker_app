// models/weekly_activity.dart

class DailyActivity {
  final DateTime date;
  final int leetcodeSubmissions;
  final int githubCommits;
  final int hackerrankSubmissions;

  DailyActivity({
    required this.date,
    required this.leetcodeSubmissions,
    required this.githubCommits,
    this.hackerrankSubmissions = 0,
  });

  int get total => leetcodeSubmissions + githubCommits + hackerrankSubmissions;
}

class WeeklyActivity {
  final List<DailyActivity> days;
  final bool isDummyData;

  WeeklyActivity({required this.days, this.isDummyData = false});

  factory WeeklyActivity.fromData({
    required Map<DateTime, int> leetcodeCalendar,
    required Map<DateTime, int> githubCalendar,
    required Map<DateTime, int> hackerrankCalendar,
  }) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));

    final List<DailyActivity> days = List.generate(7, (i) {
      final date = DateTime(monday.year, monday.month, monday.day + i);
      final normalized = DateTime(date.year, date.month, date.day);
      
      return DailyActivity(
        date: date,
        leetcodeSubmissions: leetcodeCalendar[normalized] ?? 0,
        githubCommits: githubCalendar[normalized] ?? 0,
        hackerrankSubmissions: hackerrankCalendar[normalized] ?? 0,
      );
    });

    // Check if the whole week is empty
    final bool isEmpty = days.every((d) => d.total == 0);
    
    if (isEmpty) {
      // Return dummy data if empty to show the chart structure (Requirement)
      return WeeklyActivity.getDummyData();
    }

    return WeeklyActivity(days: days);
  }

  static WeeklyActivity getDummyData() {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final List<int> lc = [2, 0, 3, 1, 4, 0, 2];
    final List<int> gh = [5, 2, 8, 4, 6, 1, 3];
    final List<int> hr = [1, 0, 0, 2, 0, 1, 0];

    return WeeklyActivity(
      days: List.generate(7, (i) => DailyActivity(
        date: DateTime(monday.year, monday.month, monday.day + i),
        leetcodeSubmissions: lc[i],
        githubCommits: gh[i],
        hackerrankSubmissions: hr[i],
      )),
      isDummyData: true,
    );
  }

  int get maxActivity =>
      days.map((d) => d.total).reduce((a, b) => a > b ? a : b);
}