import 'package:flutter/foundation.dart';
import '../models/github_stats.dart';
import '../services/github_service.dart';

class GithubProvider extends ChangeNotifier {
  final _service = GithubService();

  GithubStats? githubStats;
  List<GithubRepository> latestRepos = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchGithubData(String username) async {
    if (username.isEmpty) return;
    
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      // Fetch in parallel for better performance
      final results = await Future.wait([
        _service.fetchStats(username),
        _service.fetchLatestRepos(username),
      ]);

      githubStats = results[0] as GithubStats;
      latestRepos = results[1] as List<GithubRepository>;
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setError(String message) {
    error = message;
    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }
}
