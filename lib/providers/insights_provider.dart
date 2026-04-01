import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../providers/stats_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/github_provider.dart';

class InsightsProvider extends ChangeNotifier {
  List<String> _insights = [];
  bool _isLoading = false;
  String? _error;

  List<String> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> refreshInsights(
    StatsProvider stats, 
    GoalProvider goals, 
    GithubProvider github,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await InsightsService.fetchDynamicInsights(stats, goals, github);
    } catch (e) {
      _error = e.toString();
      _insights = ['Stay focused on your journey! 🚀'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
