import 'package:flutter/foundation.dart';
import '../models/leetcode_stats.dart';
import '../models/platform_stats.dart';
import '../models/developer_score.dart';
import '../services/leetcode_service.dart';
import '../services/codeforces_service.dart';
import '../services/codechef_service.dart';
import '../services/gfg_service.dart';

class StatsProvider extends ChangeNotifier {
  // ── Stats data ────────────────────────────────────────────────────────
  LeetcodeStats? _leetcodeStats;
  PlatformStats? _codeforcesStats;
  PlatformStats? _codechefStats;
  PlatformStats? _gfgStats;

  // ── Per-platform loading flags ─────────────────────────────────────────
  // Using per-platform flags instead of one global _isLoading means:
  // - Each platform's card can show its own spinner independently
  // - One slow/failing platform doesn't block the others from displaying
  bool _leetcodeLoading = false;
  bool _codeforcesLoading = false;
  bool _codechefLoading = false;
  bool _gfgLoading = false;

  // ── Per-platform errors ───────────────────────────────────────────────
  String? _leetcodeError;
  String? _codeforcesError;
  String? _codechefError;
  String? _gfgError;

  // ── Cache timestamps ──────────────────────────────────────────────────
  // Prevents refetching on every screen visit / hot restart
  DateTime? _leetcodeLastFetch;
  DateTime? _codeforcesLastFetch;
  DateTime? _codechefLastFetch;
  DateTime? _gfgLastFetch;

  // 10 minutes for LeetCode (rate-limited proxy), 5 min for others
  static const _leetcodeCacheDuration = Duration(minutes: 10);
  static const _otherCacheDuration = Duration(minutes: 5);

  // ── GitHub data ───────────────────────────────────────────────────────
  Map<DateTime, int> _githubCommitCalendar = {};
  int _githubStars = 0;
  int _githubTotalCommits = 0;

  // ── Public getters — stats ─────────────────────────────────────────────
  LeetcodeStats? get leetcodeStats => _leetcodeStats;
  PlatformStats? get codeforcesStats => _codeforcesStats;
  PlatformStats? get codechefStats => _codechefStats;
  PlatformStats? get gfgStats => _gfgStats;

  // ── Public getters — loading ───────────────────────────────────────────
  // Global isLoading = true only while ALL platforms are still loading
  // (used by screens that don't care which platform is loading)
  bool get isLoading =>
      _leetcodeLoading || _codeforcesLoading || _codechefLoading || _gfgLoading;

  bool get leetcodeLoading => _leetcodeLoading;
  bool get codeforcesLoading => _codeforcesLoading;
  bool get codechefLoading => _codechefLoading;
  bool get gfgLoading => _gfgLoading;

  // ── Public getters — errors ────────────────────────────────────────────
  // Legacy single error getter — returns the first non-null error
  String? get error => _leetcodeError ?? _codeforcesError ?? _codechefError ?? _gfgError;

  String? get leetcodeError => _leetcodeError;
  String? get codeforcesError => _codeforcesError;
  String? get codechefError => _codechefError;
  String? get gfgError => _gfgError;

  Map<DateTime, int> get githubCommitCalendar => _githubCommitCalendar;

  // ── Developer score ────────────────────────────────────────────────────
  DeveloperScore? get developerScore {
    if (_leetcodeStats == null) return null;
    final totalSolved = _leetcodeStats!.totalSolved +
        (_codeforcesStats?.totalSolved ?? 0) +
        (_codechefStats?.totalSolved ?? 0) +
        (_gfgStats?.totalSolved ?? 0);
    return DeveloperScore.calculate(
      leetcodeProblems: totalSolved,
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

  // ── Legacy setError (kept for compatibility with CodingStatsScreen) ────
  void setError(String message) {
    _leetcodeError = message;
    _leetcodeLoading = false;
    notifyListeners();
  }

  // ── LeetCode ───────────────────────────────────────────────────────────
  Future<void> fetchLeetCodeStats(String username, {bool forceRefresh = false}) async {
    // Return cached data if still fresh — this is the fix for 429 errors.
    // The proxy (alfa-leetcode-api.onrender.com) rate-limits aggressively,
    // so we must not call it on every screen visit.
    if (!forceRefresh &&
        _isFresh(_leetcodeLastFetch, _leetcodeCacheDuration) &&
        _leetcodeStats != null) {
      debugPrint("LeetCode: serving from cache");
      return;
    }

    _leetcodeLoading = true;
    _leetcodeError = null;
    notifyListeners();

    try {
      _leetcodeStats = await LeetcodeService().fetchData(username);
      _leetcodeLastFetch = DateTime.now();
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _leetcodeError = (msg.contains('TimeoutException') || msg.contains('TIMEOUT_ERROR'))
          ? "Server is taking too long to respond. Please try again later."
          : msg;
      debugPrint("LeetCode fetch error: $e");
    }

    _leetcodeLoading = false;
    notifyListeners();
  }

  // ── Codeforces ─────────────────────────────────────────────────────────
  Future<void> fetchCodeforcesStats(String username, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isFresh(_codeforcesLastFetch, _otherCacheDuration) &&
        _codeforcesStats != null) {
      debugPrint("Codeforces: serving from cache");
      return;
    }

    _codeforcesLoading = true;
    _codeforcesError = null;
    notifyListeners();

    try {
      _codeforcesStats = await CodeforcesService().fetchData(username);
      _codeforcesLastFetch = DateTime.now();
    } catch (e) {
      _codeforcesError = e.toString().replaceAll('Exception: ', '');
      debugPrint("Codeforces fetch error: $e");
    }

    _codeforcesLoading = false;
    notifyListeners();
  }

  // ── CodeChef ───────────────────────────────────────────────────────────
  Future<void> fetchCodeChefStats(String username, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isFresh(_codechefLastFetch, _otherCacheDuration) &&
        _codechefStats != null) {
      debugPrint("CodeChef: serving from cache");
      return;
    }

    _codechefLoading = true;
    _codechefError = null;
    notifyListeners();

    try {
      _codechefStats = await CodeChefService().fetchData(username);
      _codechefLastFetch = DateTime.now();
    } catch (e) {
      _codechefError = e.toString().replaceAll('Exception: ', '');
      debugPrint("CodeChef fetch error: $e");
    }

    _codechefLoading = false;
    notifyListeners();
  }

  // ── GFG ────────────────────────────────────────────────────────────────
  Future<void> fetchGfgStats(String username, {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _isFresh(_gfgLastFetch, _otherCacheDuration) &&
        _gfgStats != null) {
      debugPrint("GFG: serving from cache");
      return;
    }

    _gfgLoading = true;
    _gfgError = null;
    notifyListeners();

    try {
      _gfgStats = await GfgService().fetchData(username);
      _gfgLastFetch = DateTime.now();
    } catch (e) {
      _gfgError = e.toString().replaceAll('Exception: ', '');
      debugPrint("GFG fetch error: $e");
    }

    _gfgLoading = false;
    notifyListeners();
  }

  // ── fetchAllStats ──────────────────────────────────────────────────────
  // Fires all platforms in parallel — each updates independently as it
  // completes, so the UI shows data platform by platform instead of waiting
  // for the slowest one.
  Future<void> fetchAllStats({
    String? leetcode,
    String? codeforces,
    String? codechef,
    String? gfg,
    bool forceRefresh = false,
  }) async {
    final futures = <Future>[];

    if (leetcode != null && leetcode.isNotEmpty) {
      futures.add(fetchLeetCodeStats(leetcode, forceRefresh: forceRefresh));
    }
    if (codeforces != null && codeforces.isNotEmpty) {
      futures.add(fetchCodeforcesStats(codeforces, forceRefresh: forceRefresh));
    }
    if (codechef != null && codechef.isNotEmpty) {
      futures.add(fetchCodeChefStats(codechef, forceRefresh: forceRefresh));
    }
    if (gfg != null && gfg.isNotEmpty) {
      futures.add(fetchGfgStats(gfg, forceRefresh: forceRefresh));
    }

    // Run all in parallel — don't await sequentially
    await Future.wait(futures, eagerError: false);
  }

  // ── Cache invalidation (call on logout / profile change) ───────────────
  void clearAllCache() {
    _leetcodeStats = null;
    _codeforcesStats = null;
    _codechefStats = null;
    _gfgStats = null;
    _leetcodeLastFetch = null;
    _codeforcesLastFetch = null;
    _codechefLastFetch = null;
    _gfgLastFetch = null;
    _leetcodeError = null;
    _codeforcesError = null;
    _codechefError = null;
    _gfgError = null;
    notifyListeners();
  }
}