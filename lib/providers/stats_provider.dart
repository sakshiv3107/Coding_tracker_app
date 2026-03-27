// lib/providers/stats_provider.dart
//
// IMPROVEMENTS v3:
//  1. Persistent disk cache (SharedPreferences) for ALL platforms so cached
//     data survives app restarts, eliminating redundant API calls on relaunch.
//  2. Exponential-backoff retry on transient failures (network, timeout, 5xx).
//  3. Friendly rate-limit messaging — LeetCode 429 is caught and shown with
//     clear guidance instead of a crash / generic error.
//  4. Fetch-deduplication: a platform that is already loading is not started
//     again (prevents duplicate calls from hot-reload / fast navigation).
//  5. `fetchAllStats` now runs all platforms in parallel via Future.wait and
//     is safe to call multiple times quickly thanks to dedup guards.
//  6. GitHub data is synced via `updateGitHubData` only once immediately
//     instead of going through StatsProvider for analytics.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/leetcode_stats.dart';
import '../models/submission.dart';
import '../models/hackerrank_stats.dart';
import '../models/platform_stats.dart';
import '../models/developer_score.dart';
import '../services/leetcode_service.dart';
import '../services/codeforces_service.dart';
import '../services/codechef_service.dart';
import '../services/hackerrank_service.dart';
import '../services/contest_service.dart';
import '../core/analytics_engine.dart';
import '../core/exceptions.dart';

// ─── Disk-cache config ────────────────────────────────────────────────────────
const _kLcPrefix = 'sp_lc_';
const _kCfPrefix = 'sp_cf_';
const _kCcPrefix = 'sp_cc_';
const _kHrPrefix = 'sp_hr_';

const _kLcMaxAge = Duration(hours: 12); // LeetCode: stricter to avoid stale
const _kOtherMaxAge = Duration(hours: 6); // Others: 6h cache

// ─── Retry config ─────────────────────────────────────────────────────────────
const _kMaxRetries = 2;
const _kBaseRetryDelay = Duration(seconds: 2); // doubles each attempt

class StatsProvider extends ChangeNotifier {
  // ── Stats data ────────────────────────────────────────────────────────────
  LeetcodeStats? _leetcodeStats;
  PlatformStats? _codeforcesStats;
  PlatformStats? _codechefStats;
  HackerRankStats? _hackerrankStats;

  // ── Per-platform loading flags ─────────────────────────────────────────────
  bool _leetcodeLoading = false;
  bool _codeforcesLoading = false;
  bool _codechefLoading = false;
  bool _hackerrankLoading = false;

  // ── Per-platform errors ───────────────────────────────────────────────────
  String? _leetcodeError;
  String? _codeforcesError;
  String? _codechefError;
  String? _hackerrankError;

  // ── Per-platform rate-limit flags ─────────────────────────────────────────
  bool _leetcodeRateLimited = false;
  bool _codeforcesRateLimited = false;
  bool _codechefRateLimited = false;
  bool _hackerrankRateLimited = false;

  // ── Error types (for UI differentiation) ──────────────────────────────────
  bool _leetcodeUserNotFound = false;
  bool _codeforcesUserNotFound = false;
  bool _codechefUserNotFound = false;
  bool _hackerrankUserNotFound = false;

  // ── In-memory cache timestamps (session-level) ────────────────────────────
  DateTime? _leetcodeLastFetch;
  DateTime? _codeforcesLastFetch;
  DateTime? _codechefLastFetch;
  DateTime? _hackerrankLastFetch;

  // Session-level cache durations (shorter than disk, prevents mid-session refetch)
  static const _kMemLcDuration = Duration(minutes: 10);
  static const _kMemOtherDuration = Duration(minutes: 5);

  // ── GitHub data ───────────────────────────────────────────────────────────
  Map<DateTime, int> _githubCommitCalendar = {};
  int _githubStars = 0;
  int _githubTotalCommits = 0;
  Map<DateTime, int> get githubCommitCalendar => _githubCommitCalendar;

  // ── Public getters — stats ─────────────────────────────────────────────────
  LeetcodeStats? get leetcodeStats => _leetcodeStats;
  PlatformStats? get codeforcesStats => _codeforcesStats;
  PlatformStats? get codechefStats => _codechefStats;
  HackerRankStats? get hackerrankStats => _hackerrankStats;

  // ── Public getters — loading ───────────────────────────────────────────────
  bool get isLoading =>
      _leetcodeLoading ||
      _codeforcesLoading ||
      _codechefLoading ||
      _hackerrankLoading;

  bool get leetcodeLoading => _leetcodeLoading;
  bool get codeforcesLoading => _codeforcesLoading;
  bool get codechefLoading => _codechefLoading;
  bool get hackerrankLoading => _hackerrankLoading;

  // ── Public getters — errors ────────────────────────────────────────────────
  String? get error =>
      _leetcodeError ?? _codeforcesError ?? _codechefError ?? _hackerrankError;
  String? get leetcodeError => _leetcodeError;
  String? get codeforcesError => _codeforcesError;
  String? get codechefError => _codechefError;
  String? get hackerrankError => _hackerrankError;

  // ── Public getters — rate limits ──────────────────────────────────────────
  bool get leetcodeRateLimited => _leetcodeRateLimited;
  bool get codeforcesRateLimited => _codeforcesRateLimited;
  bool get codechefRateLimited => _codechefRateLimited;
  bool get hackerrankRateLimited => _hackerrankRateLimited;

  // ── Public getters — error types ──────────────────────────────────────────
  bool get leetcodeUserNotFound => _leetcodeUserNotFound;
  bool get codeforcesUserNotFound => _codeforcesUserNotFound;
  bool get codechefUserNotFound => _codechefUserNotFound;
  bool get hackerrankUserNotFound => _hackerrankUserNotFound;

  int get totalSolved =>
      (_leetcodeStats?.totalSolved ?? 0) +
      (_codeforcesStats?.totalSolved ?? 0) +
      (_codechefStats?.totalSolved ?? 0) +
      (_hackerrankStats?.totalSolved ?? 0);

  // ── Developer score ────────────────────────────────────────────────────────
  DeveloperScore? get developerScore {
    final lc = _leetcodeStats;
    if (lc == null) return null;
    return DeveloperScore.calculate(
      totalProblems: totalSolved,
      contestRating: lc.contestRating ?? 0.0,
      githubStars: _githubStars,
      totalCommits: _githubTotalCommits,
    );
  }

  // ── Analytics & Gamification ───────────────────────────────────────────────
  int _xpPoints = 0;
  Map<String, List<String>> _topicStrengths = {};
  String? _aiRecommendation = 'Connecting sources...';
  Map<DateTime, int> _progressData = {};
  List<Submission> _failedProblems = [];

  int get xpPoints => _xpPoints;
  Map<String, List<String>> get topicStrengths => _topicStrengths;
  String? get aiRecommendation => _aiRecommendation;
  Map<DateTime, int> get progressData => _progressData;
  List<Submission> get failedProblems => _failedProblems;

  List<Contest> _upcomingContests = [];
  bool _contestsLoading = false;
  List<Contest> get upcomingContests => _upcomingContests;
  bool get contestsLoading => _contestsLoading;

  // ── Cache helpers ──────────────────────────────────────────────────────────
  bool _isFresh(DateTime? lastFetch, Duration duration) =>
      lastFetch != null && DateTime.now().difference(lastFetch) < duration;

  // ── GitHub ─────────────────────────────────────────────────────────────────
  void updateGitHubData({
    required Map<DateTime, int> commitCalendar,
    required int stars,
    required int totalCommits,
  }) {
    _githubCommitCalendar = commitCalendar;
    _githubStars = stars;
    _githubTotalCommits = totalCommits;
    // Delay notification to ensure it doesn't happen during a build (called from HomeScreen)
    Future.microtask(() {
      notifyListeners();
    });
  }

  /// Legacy compatibility shim.
  void setError(String message) {
    _leetcodeError = message;
    _leetcodeLoading = false;
    notifyListeners();
  }

  // ── Contests ────────────────────────────────────────────────────────────────
  Future<void> fetchUpcomingContests() async {
    if (_contestsLoading) return; // dedup
    _contestsLoading = true;
    notifyListeners();
    try {
      _upcomingContests = await ContestService().fetchUpcomingContests();
    } catch (e) {
      debugPrint('[Contests] fetch error: $e');
    }
    _contestsLoading = false;
    notifyListeners();
  }

  // ── Analytics calculation (no notify) ─────────────────────────────────────
  void _calculateAnalytics() {
    final lc = _leetcodeStats;
    if (lc == null) {
      _failedProblems = [];
      _progressData = {};
      _aiRecommendation = null;
      return;
    }

    // Defensive check for potential nulls in tagStats if partially parsed from disk
    final tags = lc.tagStats ?? {};

    try {
      _topicStrengths = AnalyticsEngine.analyzeTopicStrengths(tags);
      _aiRecommendation = AnalyticsEngine.getDailyRecommendation(lc);
      _xpPoints = AnalyticsEngine.calculateXP(
        totalSolved: totalSolved,
        streak: lc.streak,
        rating: lc.rating,
        contestsAttended: lc.totalContests,
      );
      _progressData = AnalyticsEngine.aggregateProgress(lc.submissionCalendar);

      if (_upcomingContests.isEmpty && !_contestsLoading) {
        Future.microtask(() => fetchUpcomingContests());
      }

      final subs = lc.recentSubmissions;
      if (subs != null) {
        _failedProblems = List<Submission>.from(
          subs,
        ).where((s) => s.status != 'Accepted').toList();
      } else {
        _failedProblems = [];
      }
    } catch (e) {
      debugPrint("[Stats] Analytics calculation error: $e");
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // DISK CACHE HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _warmFromDisk() async {
    // Called on first load to restore cached data instantly without showing
    // skeletons for platforms where we have valid cached data.
    await Future.wait([
      _loadLcFromDisk(),
      _loadCfFromDisk(),
      _loadCcFromDisk(),
      _loadHrFromDisk(),
    ]);
  }

  Future<void> _loadLcFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLcPrefix);
      final tsMs = prefs.getInt('${_kLcPrefix}_ts');
      if (raw == null || tsMs == null) return;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs),
      );
      if (age > _kLcMaxAge) return;
      _leetcodeStats = LeetcodeStats.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _leetcodeLastFetch = DateTime.fromMillisecondsSinceEpoch(tsMs);
      _calculateAnalytics();
      debugPrint(
        '[StatsProvider] ✅ LC disk cache loaded (${age.inMinutes}m old)',
      );
    } catch (e) {
      debugPrint('[StatsProvider] LC disk load error: $e');
    }
  }

  Future<void> _saveLcToDisk(LeetcodeStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLcPrefix, jsonEncode(stats.toJson()));
      await prefs.setInt(
        '${_kLcPrefix}_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[StatsProvider] LC disk save error: $e');
    }
  }

  Future<void> _loadCfFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCfPrefix);
      final tsMs = prefs.getInt('${_kCfPrefix}_ts');
      if (raw == null || tsMs == null) return;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs),
      );
      if (age > _kOtherMaxAge) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _codeforcesStats = PlatformStats(
        platform: json['platform'] ?? 'Codeforces',
        username: json['username'] ?? '',
        totalSolved: json['totalSolved'] ?? 0,
        rating: json['rating'] as int?,
        rank: json['rank'] as String?,
      );
      _codeforcesLastFetch = DateTime.fromMillisecondsSinceEpoch(tsMs);
      debugPrint('[StatsProvider] ✅ CF disk cache loaded');
    } catch (e) {
      debugPrint('[StatsProvider] CF disk load error: $e');
    }
  }

  Future<void> _saveCfToDisk(PlatformStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'platform': stats.platform,
        'username': stats.username,
        'totalSolved': stats.totalSolved,
        'rating': stats.rating,
        'rank': stats.rank,
      };
      await prefs.setString(_kCfPrefix, jsonEncode(data));
      await prefs.setInt(
        '${_kCfPrefix}_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[StatsProvider] CF disk save error: $e');
    }
  }

  Future<void> _loadCcFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCcPrefix);
      final tsMs = prefs.getInt('${_kCcPrefix}_ts');
      if (raw == null || tsMs == null) return;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs),
      );
      if (age > _kOtherMaxAge) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _codechefStats = PlatformStats(
        platform: json['platform'] ?? 'CodeChef',
        username: json['username'] ?? '',
        totalSolved: json['totalSolved'] ?? 0,
        rating: json['rating'] as int?,
        rank: json['rank'] as String?,
      );
      _codechefLastFetch = DateTime.fromMillisecondsSinceEpoch(tsMs);
      debugPrint('[StatsProvider] ✅ CC disk cache loaded');
    } catch (e) {
      debugPrint('[StatsProvider] CC disk load error: $e');
    }
  }

  Future<void> _saveCcToDisk(PlatformStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'platform': stats.platform,
        'username': stats.username,
        'totalSolved': stats.totalSolved,
        'rating': stats.rating,
        'rank': stats.rank,
      };
      await prefs.setString(_kCcPrefix, jsonEncode(data));
      await prefs.setInt(
        '${_kCcPrefix}_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[StatsProvider] CC disk save error: $e');
    }
  }

  Future<void> _loadHrFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kHrPrefix);
      final tsMs = prefs.getInt('${_kHrPrefix}_ts');
      if (raw == null || tsMs == null) return;
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(tsMs),
      );
      if (age > _kOtherMaxAge) return;
      _hackerrankStats = HackerRankStats.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _hackerrankLastFetch = DateTime.fromMillisecondsSinceEpoch(tsMs);
      debugPrint('[StatsProvider] ✅ HR disk cache loaded');
    } catch (e) {
      debugPrint('[StatsProvider] HR disk load error: $e');
    }
  }

  Future<void> _saveHrToDisk(HackerRankStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kHrPrefix, jsonEncode(stats.toJson()));
      await prefs.setInt(
        '${_kHrPrefix}_ts',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[StatsProvider] HR disk save error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RETRY HELPER
  // ════════════════════════════════════════════════════════════════════════════

  /// Runs [fn] with exponential backoff.
  /// On a rate-limit error (429) it waits **longer** before retrying.
  /// On user-not-found it bails immediately.
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    String platform = '',
  }) async {
    for (var attempt = 0; attempt <= _kMaxRetries; attempt++) {
      try {
        return await fn();
      } on UserNotFoundException {
        rethrow; // never retry for user-not-found
      } on ValidationException {
        rethrow;
      } catch (e) {
        final msg = e.toString();
        final isRateLimit =
            msg.contains('429') || msg.toLowerCase().contains('rate limit');
        final isLastAttempt = attempt >= _kMaxRetries;

        if (isLastAttempt) {
          debugPrint('[$platform] ❌ All retries exhausted: $msg');
          rethrow;
        }

        // Exponential backoff: 2s, 4s, 8s …
        // Rate-limited? quadruple the wait time
        final delay = _kBaseRetryDelay * (1 << attempt) * (isRateLimit ? 4 : 1);
        debugPrint(
          '[$platform] ⚠️ Attempt ${attempt + 1} failed, retrying in '
          '${delay.inSeconds}s: $msg',
        );
        await Future.delayed(delay);
      }
    }
    throw Exception('[$platform] Retry loop exited unexpectedly');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ERROR HANDLER
  // ════════════════════════════════════════════════════════════════════════════

  String _handleError(
    dynamic e,
    String platform, {
    required void Function(bool) setUserNotFound,
    required void Function(bool) setRateLimited,
  }) {
    debugPrint('[$platform] fetch error: $e');

    if (e is ValidationException) return e.message;

    if (e is UserNotFoundException) {
      setUserNotFound(true);
      return e.message;
    }

    final msg = e.toString().replaceAll('Exception: ', '');

    // Rate-limit specific friendly message
    if (msg.contains('429') || msg.toLowerCase().contains('rate limit')) {
      setRateLimited(true);
      return '⚠️ $platform API is currently rate-limiting requests. '
          'Cached data is shown. Please wait a few minutes and pull down to refresh.';
    }

    if (msg.contains('TimeoutException') || msg.contains('TIMEOUT_ERROR')) {
      return 'Server took too long to respond. Check your connection and retry.';
    }

    if (msg.contains('SocketException') ||
        msg.contains('No address') ||
        msg.contains('Connection refused')) {
      return 'No internet connection. Cached data is shown.';
    }

    return msg;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // VALIDATION
  // ════════════════════════════════════════════════════════════════════════════

  bool _validateUsername(
    String? username,
    String platform,
    void Function(String) setError,
  ) {
    if (username == null || username.trim().isEmpty) {
      setError('$platform username required');
      return false;
    }
    return true;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LeetCode
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> fetchLeetCodeStats(
    String? username, {
    bool forceRefresh = false,
  }) async {
    if (!_validateUsername(username, 'LeetCode', (e) => _leetcodeError = e)) {
      notifyListeners();
      return;
    }

    // Dedup: skip if already loading
    if (_leetcodeLoading) return;

    // Session-level in-memory cache check
    if (!forceRefresh &&
        _isFresh(_leetcodeLastFetch, _kMemLcDuration) &&
        _leetcodeStats != null) {
      return;
    }

    _leetcodeLoading = true;
    _leetcodeError = null;
    _leetcodeUserNotFound = false;
    _leetcodeRateLimited = false;
    notifyListeners();

    try {
      // LeetcodeService handles its own memory + disk cache internally.
      // We pass forceRefresh through so the user's explicit pull-to-refresh
      // bypasses both layers.
      final stats = await _withRetry(
        () =>
            LeetcodeService().fetchData(username!, forceRefresh: forceRefresh),
        platform: 'LeetCode',
      );
      _leetcodeStats = stats;
      _leetcodeLastFetch = DateTime.now();
      await _saveLcToDisk(stats);
      _calculateAnalytics();
    } catch (e) {
      _leetcodeError = _handleError(
        e,
        'LeetCode',
        setUserNotFound: (v) => _leetcodeUserNotFound = v,
        setRateLimited: (v) => _leetcodeRateLimited = v,
      );
      // If we have stale data on disk warm loaded, keep showing it
    }

    _leetcodeLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Codeforces
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> fetchCodeforcesStats(
    String? username, {
    bool forceRefresh = false,
  }) async {
    if (!_validateUsername(
      username,
      'Codeforces',
      (e) => _codeforcesError = e,
    )) {
      notifyListeners();
      return;
    }
    if (_codeforcesLoading) return;

    if (!forceRefresh &&
        _isFresh(_codeforcesLastFetch, _kMemOtherDuration) &&
        _codeforcesStats != null) {
      return;
    }

    _codeforcesLoading = true;
    _codeforcesError = null;
    _codeforcesUserNotFound = false;
    _codeforcesRateLimited = false;
    notifyListeners();

    try {
      final stats = await _withRetry(
        () => CodeforcesService().fetchData(username!),
        platform: 'Codeforces',
      );
      _codeforcesStats = stats;
      _codeforcesLastFetch = DateTime.now();
      await _saveCfToDisk(stats);
    } catch (e) {
      _codeforcesError = _handleError(
        e,
        'Codeforces',
        setUserNotFound: (v) => _codeforcesUserNotFound = v,
        setRateLimited: (v) => _codeforcesRateLimited = v,
      );
    }

    _codeforcesLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CodeChef
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> fetchCodeChefStats(
    String? username, {
    bool forceRefresh = false,
  }) async {
    if (!_validateUsername(username, 'CodeChef', (e) => _codechefError = e)) {
      notifyListeners();
      return;
    }
    if (_codechefLoading) return;

    if (!forceRefresh &&
        _isFresh(_codechefLastFetch, _kMemOtherDuration) &&
        _codechefStats != null) {
      return;
    }

    _codechefLoading = true;
    _codechefError = null;
    _codechefUserNotFound = false;
    _codechefRateLimited = false;
    notifyListeners();

    try {
      final stats = await _withRetry(
        () => CodeChefService().fetchData(username!),
        platform: 'CodeChef',
      );
      _codechefStats = stats;
      _codechefLastFetch = DateTime.now();
      await _saveCcToDisk(stats);
    } catch (e) {
      _codechefError = _handleError(
        e,
        'CodeChef',
        setUserNotFound: (v) => _codechefUserNotFound = v,
        setRateLimited: (v) => _codechefRateLimited = v,
      );
    }

    _codechefLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // HackerRank
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> fetchHackerRankStats(
    String? username, {
    bool forceRefresh = false,
  }) async {
    if (!_validateUsername(
      username,
      'HackerRank',
      (e) => _hackerrankError = e,
    )) {
      notifyListeners();
      return;
    }
    if (_hackerrankLoading) return;

    if (!forceRefresh &&
        _isFresh(_hackerrankLastFetch, _kMemOtherDuration) &&
        _hackerrankStats != null) {
      return;
    }

    _hackerrankLoading = true;
    _hackerrankError = null;
    _hackerrankUserNotFound = false;
    _hackerrankRateLimited = false;
    notifyListeners();

    try {
      final stats = await _withRetry(
        () => HackerRankService().fetchData(username!),
        platform: 'HackerRank',
      );
      _hackerrankStats = stats;
      _hackerrankLastFetch = DateTime.now();
      await _saveHrToDisk(stats);
    } catch (e) {
      _hackerrankError = _handleError(
        e,
        'HackerRank',
        setUserNotFound: (v) => _hackerrankUserNotFound = v,
        setRateLimited: (v) => _hackerrankRateLimited = v,
      );
    }

    _hackerrankLoading = false;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Fetch All (parallel)
  // ════════════════════════════════════════════════════════════════════════════

  /// Warms UI from disk cache first (instant), then fetches fresh data
  /// in parallel. Call this once from HomeScreen.initState.
  Future<void> initializeAndFetch({
    String? leetcode,
    String? codeforces,
    String? codechef,
    String? hackerrank,
  }) async {
    // 1. Warm from disk immediately (no network, shows cached UI fast)
    await _warmFromDisk();
    _calculateAnalytics(); // Recalculate based on disk data

    // Delayed to avoid trigger during build
    Future.microtask(() => notifyListeners());

    // 2. Kick off parallel network refresh
    await fetchAllStats(
      leetcode: leetcode,
      codeforces: codeforces,
      codechef: codechef,
      hackerrank: hackerrank,
    );
  }

  /// Fetches all platforms in parallel. Safe to call multiple times — platforms
  /// already loading are skipped automatically via dedup guards.
  Future<void> fetchAllStats({
    String? leetcode,
    String? codeforces,
    String? codechef,
    String? hackerrank,
    bool forceRefresh = false,
  }) async {
    await Future.wait([
      fetchLeetCodeStats(leetcode, forceRefresh: forceRefresh),
      fetchCodeforcesStats(codeforces, forceRefresh: forceRefresh),
      fetchCodeChefStats(codechef, forceRefresh: forceRefresh),
      fetchHackerRankStats(hackerrank, forceRefresh: forceRefresh),
    ], eagerError: false);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Cache Management
  // ════════════════════════════════════════════════════════════════════════════

  /// Clears all in-memory AND disk caches.
  Future<void> clearAllCache() async {
    _leetcodeStats = null;
    _codeforcesStats = null;
    _codechefStats = null;
    _hackerrankStats = null;
    _leetcodeLastFetch = null;
    _codeforcesLastFetch = null;
    _codechefLastFetch = null;
    _hackerrankLastFetch = null;
    _leetcodeError = null;
    _codeforcesError = null;
    _codechefError = null;
    _hackerrankError = null;
    _leetcodeUserNotFound = false;
    _codeforcesUserNotFound = false;
    _codechefUserNotFound = false;
    _hackerrankUserNotFound = false;
    _leetcodeRateLimited = false;
    _codeforcesRateLimited = false;
    _codechefRateLimited = false;
    _hackerrankRateLimited = false;

    // Also clear disk
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final prefix in [_kLcPrefix, _kCfPrefix, _kCcPrefix, _kHrPrefix]) {
        await prefs.remove(prefix);
        await prefs.remove('${prefix}_ts');
      }
    } catch (_) {}

    notifyListeners();
  }
}
