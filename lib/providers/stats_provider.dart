// providers/stats_provider.dart (ENHANCED)
// Add this to your existing StatsProvider — includes GitHub calendar map
// and DeveloperScore computation.

import 'package:flutter/foundation.dart';
import '../models/leetcode_stats.dart';
import '../models/developer_score.dart';
import '../services/leetcode_service.dart';

class StatsProvider extends ChangeNotifier {
  LeetcodeStats? _leetcodeStats;
  bool _isLoading = false;
  String? _error;

  // GitHub data (populated from your existing GitHubService)
  Map<DateTime, int> _githubCommitCalendar = {};
  int _githubStars = 0;
  int _githubTotalCommits = 0;

  LeetcodeStats? get leetcodeStats => _leetcodeStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<DateTime, int> get githubCommitCalendar => _githubCommitCalendar;

  DeveloperScore? get developerScore {
    if (_leetcodeStats == null) return null;
    return DeveloperScore.calculate(
      leetcodeProblems: _leetcodeStats!.totalSolved,
      contestRating: _leetcodeStats!.contestRating ?? 0,
      githubStars: _githubStars,
      totalCommits: _githubTotalCommits,
    );
  }

  void setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Call this from your existing GitHub provider sync or GitHubService
  void updateGitHubData({
    required Map<DateTime, int> commitCalendar,
    required int stars,
    required int totalCommits,
  }) {
    _githubCommitCalendar = commitCalendar;
    _githubStars = stars;
    _githubTotalCommits = totalCommits;
    notifyListeners();
  }

  Future<void> fetchLeetCodeStats(String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final service = LeetcodeService();
      _leetcodeStats = await service.fetchData(username);
      _isLoading = false;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }
}