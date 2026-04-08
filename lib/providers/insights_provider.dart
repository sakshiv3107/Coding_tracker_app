import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import '../providers/stats_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/github_provider.dart';

class InsightsProvider extends ChangeNotifier {
  List<String> _insights = [];
  bool _isLoading = false;
  String? _error;

  // Cache insights for 4 hours — avoids burning API quota on every refresh
  DateTime? _lastFetched;
  static const _cacheTtl = Duration(hours: 4);

  List<String> get insights => _insights;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get _isCacheValid =>
      _lastFetched != null &&
      _insights.isNotEmpty &&
      DateTime.now().difference(_lastFetched!) < _cacheTtl;

  Future<void> refreshInsights(
    StatsProvider stats,
    GoalProvider goals,
    GithubProvider github, {
    bool force = false,
  }) async {
    // Skip the API call if cache is still fresh and not forced
    if (!force && _isCacheValid) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _insights = await InsightsService.fetchDynamicInsights(stats, goals, github);
      _lastFetched = DateTime.now();
    } catch (e) {
      _error = e.toString();
      // Keep existing insights if we have them rather than showing empty
      if (_insights.isEmpty) {
        _insights = [
          '📈 Keep solving consistently to build your streak.',
          '🚀 Try harder problems to level up faster.',
        ];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force a fresh fetch, ignoring cache (call after user explicitly taps refresh)
  Future<void> forceRefresh(
    StatsProvider stats,
    GoalProvider goals,
    GithubProvider github,
  ) => refreshInsights(stats, goals, github, force: true);
}
