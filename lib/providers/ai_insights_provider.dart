// lib/providers/ai_insights_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/insight_model.dart';
import '../services/ai_service.dart';
import '../services/insight_engine.dart';
import '../services/topic_classifier_service.dart';
import '../services/recommendation_engine.dart';
import 'stats_provider.dart';
import 'github_provider.dart';
import 'goal_provider.dart';

class AIInsightsProvider extends ChangeNotifier {
  // ─── State ──────────────────────────────────────────────────────────────────
  List<InsightModel> _insights = [];
  ActionPlanModel? _currentActionPlan;
  List<RecommendationModel> _recommendations = [];

  bool _insightsLoading = false;
  bool _actionPlanLoading = false;
  bool _recommendationsLoading = false;

  String? _insightsError;
  String? _actionPlanError;
  String? _recommendationsError;

  // Active topic being planned
  String? _activeTopic;

  // Gamification
  int _xp = 0;
  int _streak = 0;
  DateTime? _lastPracticed;

  // Cache
  static const _cacheKey = 'ai_insights_v3';
  static const _cacheTtl = Duration(hours: 4);
  DateTime? _lastInsightFetch;
  DateTime? _lastRecFetch;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  List<InsightModel> get insights => _insights;
  ActionPlanModel? get currentActionPlan => _currentActionPlan;
  List<RecommendationModel> get recommendations => _recommendations;

  bool get insightsLoading => _insightsLoading;
  bool get actionPlanLoading => _actionPlanLoading;
  bool get recommendationsLoading => _recommendationsLoading;

  String? get insightsError => _insightsError;
  String? get actionPlanError => _actionPlanError;
  String? get recommendationsError => _recommendationsError;
  String? get activeTopic => _activeTopic;

  int get xp => _xp;
  int get streak => _streak;
  int get level => (_xp / 500).floor() + 1;
  double get xpProgressToNextLevel => (_xp % 500) / 500.0;

  // ─── Initialization ───────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadFromDisk();
  }

  // ─── Fetch Structured AI Insights ────────────────────────────────────────────
  Future<void> fetchInsights({
    required StatsProvider stats,
    required GoalProvider goals,
    required GithubProvider github,
    bool force = false,
  }) async {
    final cacheValid = _lastInsightFetch != null &&
        _insights.isNotEmpty &&
        DateTime.now().difference(_lastInsightFetch!) < _cacheTtl;
    if (!force && cacheValid) return;

    _insightsLoading = true;
    _insightsError = null;
    notifyListeners();

    try {
      final userData = await _buildUserData(stats, goals, github);
      
      // Generate Insights (Rules + AI fallback)
      _insights = await InsightEngine.analyzeUserData(userData);
      _lastInsightFetch = DateTime.now();

      // Refresh Recommendations
      await refreshRecommendations(stats, goals: goals, github: github);
    } catch (e) {
      debugPrint('[AIInsightsProvider] Fetch Error: $e');
      _insightsError = e.toString().replaceAll('Exception: ', '');
      if (_insights.isEmpty) _insights = _fallbackInsights();
    } finally {
      _insightsLoading = false;
      notifyListeners();
    }
    await _saveToDisk();
  }

  // ─── Smart Recommendations ────────────────────────────────────────────────────
  Future<void> refreshRecommendations(
    StatsProvider stats, {
    GoalProvider? goals,
    GithubProvider? github,
    bool force = false,
  }) async {
    final cacheValid = _lastRecFetch != null &&
        _recommendations.isNotEmpty &&
        DateTime.now().difference(_lastRecFetch!) < _cacheTtl;
    if (!force && cacheValid) return;

    _recommendationsLoading = true;
    _recommendationsError = null;
    notifyListeners();
    try {
      final userData = await _buildUserData(stats, goals, github);
      _recommendations = await RecommendationEngine.generateRecommendations(
        userData: userData,
        insights: _insights,
      );
      _lastRecFetch = DateTime.now();
    } catch (e) {
      debugPrint('[AIInsightsProvider] Rec Error: $e');
      _recommendationsError = e.toString().replaceAll('Exception: ', '');
      if (_recommendations.isEmpty) {
        _recommendations = _fallbackRecommendations();
      }
    } finally {
      _recommendationsLoading = false;
      notifyListeners();
    }
  }

  // ─── Generate Action Plan ─────────────────────────────────────────────────────
  Future<void> generateActionPlan(InsightModel insight) async {
    _actionPlanLoading = true;
    _actionPlanError = null;
    _activeTopic = insight.topic;
    _currentActionPlan = null;
    notifyListeners();

    try {
      final numericConfidence = insight.confidence.toLowerCase() == 'high' 
          ? 0.9 
          : (insight.confidence.toLowerCase() == 'medium' ? 0.6 : 0.4);

      final rawJson = await AIService.generateActionPlan(
        topic: insight.topic,
        insightTitle: insight.title,
        insightId: insight.id,
        weaknessLevel: 1.0 - numericConfidence,
      );
      _currentActionPlan = ActionPlanModel.fromJson(
        rawJson as Map<String, dynamic>,
        insight.id,
      );
    } catch (e) {
      _actionPlanError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _actionPlanLoading = false;
      notifyListeners();
    }
  }

  // ─── Log Practice (XP/Streak only, no Mistake Tracking) ───────────────────────
  void logPracticeResult({
    required bool correct,
    int points = 0,
  }) {
    _xp += points > 0 ? points : (correct ? 50 : 10);

    final today = DateTime.now();
    if (_lastPracticed == null ||
        today.difference(_lastPracticed!).inDays >= 1) {
      if (_lastPracticed != null && today.difference(_lastPracticed!).inDays == 1) {
        _streak++;
      } else if (_lastPracticed == null) {
        _streak = 1;
      }
      _lastPracticed = today;
    }

    notifyListeners();
    _saveToDisk();
  }

  void clearActionPlan() {
    _currentActionPlan = null;
    _activeTopic = null;
    _actionPlanError = null;
    notifyListeners();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _buildUserData(
    StatsProvider stats,
    GoalProvider? goals,
    GithubProvider? github,
  ) async {
    // Group recent submissions by topic accurately
    final recentSubs = stats.leetcodeStats?.recentSubmissions ?? [];
    final topicPerformance = <String, Map<String, int>>{};

    for (var i = 0; i < recentSubs.length && i < 20; i++) {
        final sub = recentSubs[i];
        final topics = await TopicClassifierService.classify(sub.title);
        final primaryTopic = topics.isNotEmpty ? topics.first : 'General';
        
        topicPerformance.putIfAbsent(primaryTopic, () => {'attempts': 0, 'correct': 0});
        topicPerformance[primaryTopic]!['attempts'] = topicPerformance[primaryTopic]!['attempts']! + 1;
        if (sub.status == 'Accepted' || sub.status == 'passed') {
            topicPerformance[primaryTopic]!['correct'] = topicPerformance[primaryTopic]!['correct']! + 1;
        }
    }

    return {
      'totalSolved': stats.totalSolved,
      'platforms': {
        'leetcode': stats.leetcodeStats?.toJson(),
        'codeforces': stats.codeforcesStats?.totalSolved ?? 0,
        'codechef': stats.codechefStats?.totalSolved ?? 0,
      },
      'recentSubmissions': stats.leetcodeStats?.recentSubmissions?.map((s) => s.toJson()).toList() ?? [],
      'topicPerformance': topicPerformance,
      'xp': _xp,
      'streak': _streak,
    };
  }

  List<InsightModel> _fallbackInsights() => [
        const InsightModel(
          id: 'fb1',
          title: 'Master Dynamic Programming',
          reason: 'DP is a core focus for advanced coding roles. Consistency is key.',
          impact: 'Critical for top company interviews.',
          confidence: 'Medium',
          topic: 'Dynamic Programming',
          type: InsightType.weakness,
          emoji: '🧩',
        ),
      ];

  List<RecommendationModel> _fallbackRecommendations() => [
        const RecommendationModel(
          title: 'Start daily DP practice',
          description: 'Try solving one Medium problem daily to build intuition.',
          icon: '🎯',
          type: 'focus',
          priority: RecommendationPriority.medium,
        ),
      ];

  // ─── Persistence ──────────────────────────────────────────────────────────────
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'xp': _xp,
        'streak': _streak,
        'lastPracticed': _lastPracticed?.toIso8601String(),
      });
      await prefs.setString(_cacheKey, data);
    } catch (e) {
      debugPrint('[AIInsightsProvider] Save error: $e');
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _xp = (json['xp'] as num?)?.toInt() ?? 0;
      _streak = (json['streak'] as num?)?.toInt() ?? 0;
      final lp = json['lastPracticed'] as String?;
      _lastPracticed = lp != null ? DateTime.tryParse(lp) : null;
    } catch (e) {
      debugPrint('[AIInsightsProvider] Load error: $e');
    }
  }
}
