// lib/providers/github_provider.dart
//
// IMPROVEMENTS:
//  1. Session-level in-memory cache (10 min) prevents redundant GitHub API
//     calls during a single app session.
//  2. Persistent disk cache (SharedPreferences, 6 h) so data survives
//     app restarts without a full network fetch.
//  3. Fetch-deduplication guard prevents concurrent calls.
//  4. Graceful error handling: network errors show friendly messages.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/github_stats.dart';
import '../services/github_service.dart';

const _kGhStatsKey = 'gh_stats';
const _kGhStatsTs = 'gh_stats_ts';
const _kGhReposKey = 'gh_repos';
const _kGhMaxAge = Duration(hours: 6);
const _kGhMemAge = Duration(minutes: 10);

class GithubProvider extends ChangeNotifier {
  final _service = GithubService();

  GithubStats? githubStats;
  List<GithubRepository> latestRepos = [];
  List<GithubStarredRepository> starredRepos = [];
  bool isLoading = false;
  String? error;

  // ── Session-level cache ───────────────────────────────────────────────────
  DateTime? _lastFetch;
  bool _fetching = false; // dedup guard

  bool get _isFresh =>
      _lastFetch != null &&
      DateTime.now().difference(_lastFetch!) < _kGhMemAge;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> fetchGithubData(String username,
      {bool forceRefresh = false}) async {
    if (username.isEmpty) return;

    // Dedup
    if (_fetching) return;

    // Session cache hit
    if (!forceRefresh && _isFresh && githubStats != null) return;

    _fetching = true;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Try disk cache first (only on first load, not force-refresh)
      if (!forceRefresh && githubStats == null) {
        await _warmFromDisk();
        if (githubStats != null) {
          // Show stale data instantly, then refresh in background
          isLoading = false;
          notifyListeners();
          _backgroundRefresh(username);
          _fetching = false;
          return;
        }
      }

      await _doFetch(username);
    } catch (e) {
      error = _friendlyError(e);
      debugPrint('[GitHub] Fetch error: $e');
    } finally {
      isLoading = false;
      _fetching = false;
      notifyListeners();
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  Future<void> _doFetch(String username) async {
    final results = await Future.wait([
      _service.fetchStats(username),
      _service.fetchLatestRepos(username),
      _service.fetchStarredRepos(username),
    ]);
    githubStats = results[0] as GithubStats;
    latestRepos = results[1] as List<GithubRepository>;
    starredRepos = results[2] as List<GithubStarredRepository>;
    _lastFetch = DateTime.now();
    error = null;
    await _saveToDisk();
  }

  void _backgroundRefresh(String username) {
    _doFetch(username).then((_) {
      notifyListeners();
    }).catchError((e) {
      debugPrint('[GitHub] Background refresh error: $e');
    });
  }

  // ── Disk cache ─────────────────────────────────────────────────────────────

  Future<void> _warmFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kGhStatsKey);
      final tsMs = prefs.getInt(_kGhStatsTs);
      if (raw == null || tsMs == null) return;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(tsMs));
      if (age > _kGhMaxAge) return;
      githubStats =
          GithubStats.fromCache(jsonDecode(raw) as Map<String, dynamic>);
      _lastFetch = DateTime.fromMillisecondsSinceEpoch(tsMs);
      debugPrint('[GitHub] ✅ disk cache loaded (${age.inMinutes}m old)');
    } catch (e) {
      debugPrint('[GitHub] disk load error: $e');
    }
  }

  Future<void> _saveToDisk() async {
    try {
      if (githubStats == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGhStatsKey, jsonEncode(githubStats!.toJson()));
      await prefs.setInt(_kGhStatsTs, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[GitHub] disk save error: $e');
    }
  }

  // ── Error messages ─────────────────────────────────────────────────────────

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('No address')) {
      return 'No internet connection. Cached GitHub data is shown.';
    }
    if (msg.contains('TimeoutException')) {
      return 'GitHub API timed out. Please try again.';
    }
    if (msg.contains('404') || msg.contains('Not Found')) {
      return 'GitHub user not found. Please check your username.';
    }
    return msg.replaceAll('Exception: ', '');
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  void setError(String message) {
    error = message;
    isLoading = false;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> clearCache() async {
    githubStats = null;
    latestRepos = [];
    starredRepos = [];
    _lastFetch = null;
    error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGhStatsKey);
      await prefs.remove(_kGhStatsTs);
      await prefs.remove(_kGhReposKey);
    } catch (_) {}
    notifyListeners();
  }
}
