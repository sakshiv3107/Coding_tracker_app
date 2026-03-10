import 'package:coding_tracker_app/models/leetcode_stats.dart';
import 'package:flutter/foundation.dart';
import '../services/leetcode_service.dart';

class StatsProvider extends ChangeNotifier {
  final _service = LeetcodeService();

  String? error;
  bool isLoading = false;
  LeetcodeStats? leetcodeStats;

  Future<void> fetchLeetCodeStats(String username) async {
    if (isLoading) return;
    try {
      isLoading = true;
      notifyListeners();

      leetcodeStats = await _service.fetchData(username);
      error = null;
    } catch (e) {
      if (e.toString().contains("TIMEOUT_ERROR") || e.toString().contains("TimeoutException")) {
        error = "The LeetCode server is taking too long to wake up. Please wait 10 seconds and try again, it will likely work then!";
      } else if (e.toString().contains("not found")) {
        error = "LeetCode user not found. Please check your username in profile.";
      } else {
        error = e.toString().replaceAll("Exception: ", "");
      }
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
