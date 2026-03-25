import 'package:flutter/foundation.dart';
import '../models/leetcode_stats.dart';
import '../models/submission.dart';
import '../models/hackerrank_stats.dart';
import '../models/gfg_stats.dart';
import '../models/platform_stats.dart';
import '../models/developer_score.dart';
import '../services/leetcode_service.dart';
import '../services/codeforces_service.dart';
import '../services/codechef_service.dart';
import '../services/gfg_service.dart';
import '../services/hackerrank_service.dart';
import '../services/contest_service.dart';
import '../core/analytics_engine.dart';
import '../core/exceptions.dart';

class StatsProvider extends ChangeNotifier {
  // ── Stats data ────────────────────────────────────────────────────────
  LeetcodeStats? _leetcodeStats;
  PlatformStats? _codeforcesStats;
  PlatformStats? _codechefStats;
  GfgStats? _gfgStats;
  HackerRankStats? _hackerrankStats;

  // ── Per-platform loading flags ─────────────────────────────────────────
  bool _leetcodeLoading = false;
  bool _codeforcesLoading = false;
  bool _codechefLoading = false;
  bool _gfgLoading = false;
  bool _hackerrankLoading = false;

  // ── Per-platform errors ───────────────────────────────────────────────
  String? _leetcodeError;
  String? _codeforcesError;
  String? _codechefError;
  String? _gfgError;
  String? _hackerrankError;

  // ── Error types (for UI differentiation) ──────────────────────────────
  bool _leetcodeUserNotFound = false;
  bool _codeforcesUserNotFound = false;
  bool _codechefUserNotFound = false;
  bool _gfgUserNotFound = false;
  bool _hackerrankUserNotFound = false;

  // ── Cache timestamps ──────────────────────────────────────────────────
  DateTime? _leetcodeLastFetch;
  DateTime? _codeforcesLastFetch;
  DateTime? _codechefLastFetch;
  DateTime? _gfgLastFetch;
  DateTime? _hackerrankLastFetch;

  static const _leetcodeCacheDuration = Duration(minutes: 10);
  static const _otherCacheDuration = Duration(minutes: 5);

  // ── GitHub data ───────────────────────────────────────────────────────
  Map<DateTime, int> _githubCommitCalendar = {};
  int _githubStars = 0;
  int _githubTotalCommits = 0;

  Map<DateTime, int> get githubCommitCalendar => _githubCommitCalendar;

  // ── Public getters — stats ─────────────────────────────────────────────
  LeetcodeStats? get leetcodeStats => _leetcodeStats;
  PlatformStats? get codeforcesStats => _codeforcesStats;
  PlatformStats? get codechefStats => _codechefStats;
  GfgStats? get gfgStats => _gfgStats;
  HackerRankStats? get hackerrankStats => _hackerrankStats;

  // ── Public getters — loading ───────────────────────────────────────────
  bool get isLoading =>
      _leetcodeLoading || _codeforcesLoading || _codechefLoading || _gfgLoading || _hackerrankLoading;

  bool get leetcodeLoading => _leetcodeLoading;
  bool get codeforcesLoading => _codeforcesLoading;
  bool get codechefLoading => _codechefLoading;
  bool get gfgLoading => _gfgLoading;
  bool get hackerrankLoading => _hackerrankLoading;


  // ── Public getters — errors ────────────────────────────────────────────
  String? get error => _leetcodeError ?? _codeforcesError ?? _codechefError ?? _gfgError ?? _hackerrankError;

  String? get leetcodeError => _leetcodeError;
  String? get codeforcesError => _codeforcesError;
  String? get codechefError => _codechefError;
  String? get gfgError => _gfgError;
  String? get hackerrankError => _hackerrankError;

  // ── Public getters — error types ──────────────────────────────────────
  bool get leetcodeUserNotFound => _leetcodeUserNotFound;
  bool get codeforcesUserNotFound => _codeforcesUserNotFound;
  bool get codechefUserNotFound => _codechefUserNotFound;
  bool get gfgUserNotFound => _gfgUserNotFound;
  bool get hackerrankUserNotFound => _hackerrankUserNotFound;

  int get totalSolved =>
      (_leetcodeStats?.totalSolved ?? 0) +
      (_codeforcesStats?.totalSolved ?? 0) +
      (_codechefStats?.totalSolved ?? 0) +
      (_gfgStats?.totalSolved ?? 0) +
      (_hackerrankStats?.totalSolved ?? 0);

  // ── Developer score ────────────────────────────────────────────────────
  DeveloperScore? get developerScore {
    if (_leetcodeStats == null) return null;
    final totalSolvedVal = totalSolved;
    return DeveloperScore.calculate(
      totalProblems: totalSolvedVal,
      contestRating: _leetcodeStats!.contestRating ?? 0,
      githubStars: _githubStars,
      totalCommits: _githubTotalCommits,
    );
  }

  // ── Cache helpers ──────────────────────────────────────────────────────
  bool _isFresh(DateTime? lastFetch, Duration duration) =>
      lastFetch != null && DateTime.now().difference(lastFetch) < duration;

  // ── GitHub ─────────────────────────────────────────────────────────────
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

  // ── Legacy setError ────────────────────────────────────────────────────
  void setError(String message) {
    _leetcodeError = message;
    _leetcodeLoading = false;
    notifyListeners();
  }

  // ─── Analytics & Gamification ──────────────────────────────────────────
  int _xpPoints = 0;
  Map<String, List<String>> _topicStrengths = {};
  String _aiRecommendation = "Connecting sources...";
  Map<DateTime, int> _progressData = {};
  List<Submission> _failedProblems = [];

  int get xpPoints => _xpPoints;
  Map<String, List<String>> get topicStrengths => _topicStrengths;
  String get aiRecommendation => _aiRecommendation;
  Map<DateTime, int> get progressData => _progressData;
  List<Submission> get failedProblems => _failedProblems;

  List<Contest> _upcomingContests = [];
  bool _contestsLoading = false;
  List<Contest> get upcomingContests => _upcomingContests;
  bool get contestsLoading => _contestsLoading;

  Future<void> fetchUpcomingContests() async {
    _contestsLoading = true;
    notifyListeners();
    try {
      _upcomingContests = await ContestService().fetchUpcomingContests();
    } catch (e) {
      debugPrint("Contest fetch error: $e");
    }
    _contestsLoading = false;
    notifyListeners();
  }

  void _calculateAnalytics() {
    if (_leetcodeStats == null) return;

    _topicStrengths = AnalyticsEngine.analyzeTopicStrengths(_leetcodeStats!.tagStats);
    _aiRecommendation = AnalyticsEngine.getDailyRecommendation(_leetcodeStats);

    _xpPoints = AnalyticsEngine.calculateXP(
      totalSolved: totalSolved,
      streak: _leetcodeStats!.streak,
      rating: _leetcodeStats!.rating,
      contestsAttended: _leetcodeStats!.totalContests,
    );

    _progressData = AnalyticsEngine.aggregateProgress(_leetcodeStats!.submissionCalendar);

    // Fetch contests lazily — do NOT call notifyListeners inside _calculateAnalytics
    if (_upcomingContests.isEmpty && !_contestsLoading) {
      Future.microtask(() => fetchUpcomingContests());
    }

    if (_leetcodeStats!.recentSubmissions != null) {
      _failedProblems = _leetcodeStats!.recentSubmissions!
          .where((s) => s.status != 'Accepted')
          .toList();
    }
    // Caller is responsible for calling notifyListeners after this
  }

  // ── Common Error Handler ───────────────────────────────────────────────
  String _handleError(dynamic e, String platform, {required Function(bool) setUserNotFound}) {
    debugPrint("$platform fetch error: $e");
    
    if (e is ValidationException) {
      return e.message;
    }
    
    if (e is UserNotFoundException) {
      setUserNotFound(true);
      return e.message;
    }

    final msg = e.toString().replaceAll('Exception: ', '');
    if (msg.contains('TimeoutException') || msg.contains('TIMEOUT_ERROR')) {
      return "Server is taking too long to respond. Please try again later.";
    }
    
    return msg;
  }

  // ── Validations ────────────────────────────────────────────────────────
  bool _validateUsername(String? username, String platform, Function(String) setError) {
    if (username == null || username.trim().isEmpty) {
      setError("$platform username required");
      return false;
    }
    return true;
  }

  // ─── LeetCode ───────────────────────────────────────────────────────────
  Future<void> fetchLeetCodeStats(String? username, {bool forceRefresh = false}) async {
    if (!_validateUsername(username, "LeetCode", (err) => _leetcodeError = err)) {
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _isFresh(_leetcodeLastFetch, _leetcodeCacheDuration) &&
        _leetcodeStats != null) {
      return;
    }

    _leetcodeLoading = true;
    _leetcodeError = null;
    _leetcodeUserNotFound = false;
    notifyListeners();

    try {
      _leetcodeStats = await LeetcodeService().fetchData(username!);
      _leetcodeLastFetch = DateTime.now();
      _calculateAnalytics();
    } catch (e) {
      _leetcodeError = _handleError(e, "LeetCode", setUserNotFound: (val) => _leetcodeUserNotFound = val);
    }

    _leetcodeLoading = false;
    notifyListeners();
  }

  // ── Codeforces ─────────────────────────────────────────────────────────
  Future<void> fetchCodeforcesStats(String? username, {bool forceRefresh = false}) async {
    if (!_validateUsername(username, "Codeforces", (err) => _codeforcesError = err)) {
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _isFresh(_codeforcesLastFetch, _otherCacheDuration) &&
        _codeforcesStats != null) {
      return;
    }

    _codeforcesLoading = true;
    _codeforcesError = null;
    _codeforcesUserNotFound = false;
    notifyListeners();

    try {
      _codeforcesStats = await CodeforcesService().fetchData(username!);
      _codeforcesLastFetch = DateTime.now();
    } catch (e) {
      _codeforcesError = _handleError(e, "Codeforces", setUserNotFound: (val) => _codeforcesUserNotFound = val);
    }

    _codeforcesLoading = false;
    notifyListeners();
  }

  // ── CodeChef ───────────────────────────────────────────────────────────
  Future<void> fetchCodeChefStats(String? username, {bool forceRefresh = false}) async {
    if (!_validateUsername(username, "CodeChef", (err) => _codechefError = err)) {
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _isFresh(_codechefLastFetch, _otherCacheDuration) &&
        _codechefStats != null) {
      return;
    }

    _codechefLoading = true;
    _codechefError = null;
    _codechefUserNotFound = false;
    notifyListeners();

    try {
      _codechefStats = await CodeChefService().fetchData(username!);
      _codechefLastFetch = DateTime.now();
    } catch (e) {
      _codechefError = _handleError(e, "CodeChef", setUserNotFound: (val) => _codechefUserNotFound = val);
    }

    _codechefLoading = false;
    notifyListeners();
  }

  // ── GFG ────────────────────────────────────────────────────────────────
  Future<void> fetchGfgStats(String? username, {bool forceRefresh = false}) async {
    if (!_validateUsername(username, "GeeksforGeeks", (err) => _gfgError = err)) {
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _isFresh(_gfgLastFetch, _otherCacheDuration) &&
        _gfgStats != null) {
      return;
    }

    _gfgLoading = true;
    _gfgError = null;
    _gfgUserNotFound = false;
    notifyListeners();

    try {
      _gfgStats = await GfgService().fetchData(username!);
      _gfgLastFetch = DateTime.now();
    } catch (e) {
      _gfgError = _handleError(e, "GFG", setUserNotFound: (val) => _gfgUserNotFound = val);
    }

    _gfgLoading = false;
    notifyListeners();
  }

  // ── HackerRank ────────────────────────────────────────────────────────
  Future<void> fetchHackerRankStats(String? username, {bool forceRefresh = false}) async {
    if (!_validateUsername(username, "HackerRank", (err) => _hackerrankError = err)) {
      notifyListeners();
      return;
    }

    if (!forceRefresh &&
        _isFresh(_hackerrankLastFetch, _otherCacheDuration) &&
        _hackerrankStats != null) {
      return;
    }

    _hackerrankLoading = true;
    _hackerrankError = null;
    _hackerrankUserNotFound = false;
    notifyListeners();

    try {
      _hackerrankStats = await HackerRankService().fetchData(username!);
      _hackerrankLastFetch = DateTime.now();
    } catch (e) {
      _hackerrankError = _handleError(e, "HackerRank", setUserNotFound: (val) => _hackerrankUserNotFound = val);
    }

    _hackerrankLoading = false;
    notifyListeners();
  }

  Future<void> fetchAllStats({
    String? leetcode,
    String? codeforces,
    String? codechef,
    String? gfg,
    String? hackerrank,
    bool forceRefresh = false,
  }) async {
    final futures = <Future>[];

    futures.add(fetchLeetCodeStats(leetcode, forceRefresh: forceRefresh));
    futures.add(fetchCodeforcesStats(codeforces, forceRefresh: forceRefresh));
    futures.add(fetchCodeChefStats(codechef, forceRefresh: forceRefresh));
    futures.add(fetchGfgStats(gfg, forceRefresh: forceRefresh));
    futures.add(fetchHackerRankStats(hackerrank, forceRefresh: forceRefresh));

    await Future.wait(futures, eagerError: false);
  }

  void clearAllCache() {
    _leetcodeStats = null;
    _codeforcesStats = null;
    _codechefStats = null;
    _gfgStats = null;
    _hackerrankStats = null;
    _leetcodeLastFetch = null;
    _codeforcesLastFetch = null;
    _codechefLastFetch = null;
    _gfgLastFetch = null;
    _hackerrankLastFetch = null;
    _leetcodeError = null;
    _codeforcesError = null;
    _codechefError = null;
    _gfgError = null;
    _hackerrankError = null;
    _leetcodeUserNotFound = false;
    _codeforcesUserNotFound = false;
    _codechefUserNotFound = false;
    _gfgUserNotFound = false;
    _hackerrankUserNotFound = false;
    notifyListeners();
  }
}