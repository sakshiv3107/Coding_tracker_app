import 'package:coding_tracker_app/models/leetcode_stats.dart';
import 'package:flutter/foundation.dart';
import '../services/leetcode_service.dart';

class StatsProvider extends ChangeNotifier {
  final _service = LeetcodeService();

  String? error;
  bool isLoading = false;
  LeetcodeStats? leetcodeStats;

  Future<void> fetchLeetCodeStats(String username) async {
    try {
      isLoading = true;
      notifyListeners();

      leetcodeStats = await _service.fetchData(username);
      error = null;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  void setError(String message) {
    error = message;
    leetcodeStats = null;
    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void reset() {
    error = null;
    isLoading = false;
    leetcodeStats = null;
    notifyListeners();
  }
}
