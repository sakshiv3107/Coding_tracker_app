// lib/screens/ai_insight_coach_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/stats_provider.dart';
import '../models/insight_model.dart';
import '../services/insight_service.dart';
import '../widgets/insight/daily_insight_banner.dart';
import '../widgets/insight/skill_gap_chart.dart';
import '../widgets/insight/focus_problems_card.dart';
import '../widgets/insight/mistake_pattern_card.dart';
import '../widgets/insight/progress_forecast_card.dart';
import '../widgets/insight/contest_readiness_card.dart';
import '../widgets/insight/weekly_report_card.dart';
import '../widgets/insight/ai_chat_coach.dart';

class AIInsightCoachScreen extends StatefulWidget {
  const AIInsightCoachScreen({super.key});

  @override
  State<AIInsightCoachScreen> createState() => _AIInsightCoachScreenState();
}

class _AIInsightCoachScreenState extends State<AIInsightCoachScreen> {
  // ── Daily Insight ──────────────────────────────────────────────────────────
  String? _bannerInsight;
  String? _bannerNudge;
  bool _bannerLoading = false;
  String? _bannerError;

  // ── Focus Problems ─────────────────────────────────────────────────────────
  List<FocusProblem>? _focusProblems;
  bool _focusLoading = false;
  String? _focusError;

  // ── Mistake Patterns ───────────────────────────────────────────────────────
  List<MistakePattern> _patterns = [];
  final Map<String, bool> _tipLoadingState = {};

  // ── Goals (multiple) ───────────────────────────────────────────────────────
  List<CoachGoal> _goals = [];

  // ── Monthly progress ───────────────────────────────────────────────────────
  int _solvedThisMonth = 0;

  // ── Contest ────────────────────────────────────────────────────────────────
  String? _upcomingContest;
  DateTime? _upcomingContestTime;

  // ── Weekly report ──────────────────────────────────────────────────────────
  Map<String, String>? _weeklyReport;
  bool _weeklyLoading = false;
  String? _weeklyError;

  // ── Chat ───────────────────────────────────────────────────────────────────
  final List<Map<String, String>> _chatHistory = [];
  bool _chatTyping = false;
  String? _chatError;

  // ── Readiness score ────────────────────────────────────────────────────────
  int _readinessScore = 0;
  Map<String, int> _readinessSubScores = {
    'Consistency': 0, 'Breadth': 0, 'Mix': 0, 'Recent': 0,
  };

  // ── Weekly snapshot (built once from stats) ────────────────────────────────
  WeeklySnapshot? _weeklySnapshot;

  // ─────────────────────────────────────────────────────────────────────────────
  // Tag alias resolution (matches skill_gap_chart.dart)
  // ─────────────────────────────────────────────────────────────────────────────
  static const _topicAliases = <String, List<String>>{
    'Arrays':              ['Array', 'Arrays'],
    'Strings':             ['String', 'Strings'],
    'Trees':               ['Tree', 'Binary Tree', 'Trees'],
    'Graphs':              ['Graph', 'Graphs', 'Graph Theory'],
    'Dynamic Programming': ['Dynamic Programming'],
    'Greedy':              ['Greedy'],
    'Backtracking':        ['Backtracking'],
    'Segment Tree':        ['Segment Tree'],
    'Bit Manipulation':    ['Bit Manipulation'],
    'Math':                ['Math', 'Mathematics'],
  };

  static const _topicThresholds = <String, int>{
    'Arrays': 50, 'Strings': 40, 'Trees': 35, 'Graphs': 30,
    'Dynamic Programming': 40, 'Greedy': 40, 'Backtracking': 20,
    'Segment Tree': 15, 'Bit Manipulation': 20, 'Math': 30,
  };

  int _resolveTag(Map<String, int> tagStats, String displayName) {
    final aliases = _topicAliases[displayName] ?? [displayName];
    int total = 0;
    for (final alias in aliases) {
      for (final entry in tagStats.entries) {
        if (entry.key.toLowerCase() == alias.toLowerCase()) total += entry.value;
      }
    }
    return total;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build a StatsSnapshot from provider data
  // ─────────────────────────────────────────────────────────────────────────────
  StatsSnapshot _buildSnapshot(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final tagStats = lc?.tagStats ?? {};

    // Score every topic and find the weakest
    final topicScores = <String, double>{};
    for (final topic in _topicAliases.keys) {
      final solved = _resolveTag(tagStats, topic);
      final threshold = _topicThresholds[topic] ?? 40;
      topicScores[topic] = (solved / threshold).clamp(0.0, 1.0);
    }
    final weakTopics = topicScores.entries
        .where((e) => e.value < 0.5)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final recentSubs = lc?.recentSubmissions ?? [];
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentCount = recentSubs.where((s) => s.timestamp.isAfter(sevenDaysAgo)).length;

    final platforms = <String>[];
    if (lc != null) platforms.add('LeetCode');
    if (stats.codeforcesStats != null) platforms.add('Codeforces');
    if (stats.codechefStats != null) platforms.add('CodeChef');
    if (stats.hackerrankStats != null) platforms.add('HackerRank');

    return StatsSnapshot(
      streak: lc?.streak ?? 0,
      totalSolved: stats.totalSolved,
      easySolved: lc?.easy ?? 0,
      mediumSolved: lc?.medium ?? 0,
      hardSolved: lc?.hard ?? 0,
      topWeakTopics: weakTopics.isEmpty
          ? ['Dynamic Programming', 'Graphs', 'Trees']
          : weakTopics.take(3).map((e) => e.key).toList(),
      recentSubmissionCount: recentCount,
      platforms: platforms,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Extract RECENT submission topics (for focus problems)
  // ─────────────────────────────────────────────────────────────────────────────
  List<String> _extractRecentTopics(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final subs = lc?.recentSubmissions ?? [];
    final tagStats = lc?.tagStats ?? {};

    // Get accepted problem titles from last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentAccepted = subs
        .where((s) =>
            s.timestamp.isAfter(sevenDaysAgo) &&
            s.status.toLowerCase().contains('accept'))
        .map((s) => s.title.toLowerCase())
        .toList();

    // Use tag stats to infer topics worked on recently
    // Top solved tags more likely correspond to recent work
    final topTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recentTopics = <String>{};

    // Map top LeetCode tags to our display names
    for (final tag in topTags.take(6)) {
      for (final entry in _topicAliases.entries) {
        if (entry.value.any((a) => a.toLowerCase() == tag.key.toLowerCase())) {
          recentTopics.add(entry.key);
        }
      }
    }

    // Heuristic guess from problem titles
    for (final title in recentAccepted) {
      if (title.contains('tree') || title.contains('trie')) recentTopics.add('Trees');
      if (title.contains('graph') || title.contains('path')) recentTopics.add('Graphs');
      if (title.contains('dynamic') || title.contains('dp')) recentTopics.add('Dynamic Programming');
      if (title.contains('sort') || title.contains('array')) recentTopics.add('Arrays');
      if (title.contains('string') || title.contains('palindrome')) recentTopics.add('Strings');
      if (title.contains('backtrack')) recentTopics.add('Backtracking');
      if (title.contains('greedy')) recentTopics.add('Greedy');
      if (title.contains('bit')) recentTopics.add('Bit Manipulation');
    }

    return recentTopics.take(4).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Contest readiness (client-side)
  // ─────────────────────────────────────────────────────────────────────────────
  void _computeReadiness(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final total = stats.totalSolved;
    final streak = lc?.streak ?? 0;
    final medium = lc?.medium ?? 0;
    final hard = lc?.hard ?? 0;
    final tagStats = lc?.tagStats ?? {};

    final consistency = ((streak / 30) * 25).clamp(0.0, 25.0).toInt();

    int aboveThreshold = 0;
    for (final topic in _topicAliases.keys) {
      final threshold = _topicThresholds[topic] ?? 16;
      final solved = _resolveTag(tagStats, topic);
      if (solved >= (threshold * 0.4).ceil()) aboveThreshold++;
    }
    final breadth = ((aboveThreshold / _topicAliases.length) * 25).toInt();
    final mix = total > 0 ? (((medium + hard) / total) * 25).toInt() : 0;

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent7 = (lc?.recentSubmissions ?? [])
        .where((s) => s.timestamp.isAfter(sevenDaysAgo))
        .length;
    final recency = ((recent7 / 7) * 25).clamp(0.0, 25.0).toInt();

    setState(() {
      _readinessSubScores = {
        'Consistency': consistency, 'Breadth': breadth, 'Mix': mix, 'Recent': recency,
      };
      _readinessScore = (consistency + breadth + mix + recency).clamp(0, 100);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Mistake pattern analysis — precise, actionable
  // ─────────────────────────────────────────────────────────────────────────────
  void _computeMistakePatterns(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final subs = lc?.recentSubmissions ?? [];
    if (subs.isEmpty) return;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recent = subs.where((s) => s.timestamp.isAfter(thirtyDaysAgo)).toList();

    // Collect specific problem names per error type
    final tleProblems = <String>[];
    final waProblems = <String>[];
    final reProblems = <String>[];
    final mleProblems = <String>[];

    for (final s in recent) {
      final status = s.status.toLowerCase();
      final title = s.title;
      if (status.contains('time limit') || status.contains('tle')) tleProblems.add(title);
      if (status.contains('wrong answer') || status.contains('wa')) waProblems.add(title);
      if (status.contains('runtime error') || status.contains('re')) reProblems.add(title);
      if (status.contains('memory limit') || status.contains('mle')) mleProblems.add(title);
    }

    final patterns = <MistakePattern>[];

    if (tleProblems.length >= 2) {
      patterns.add(MistakePattern(
        patternName: 'Time Limit Exceeded (TLE)',
        count: tleProblems.length,
        severity: 'red',
        detail: _uniqueTitles(tleProblems),
      ));
    }
    if (waProblems.length >= 2) {
      patterns.add(MistakePattern(
        patternName: 'Wrong Answer (WA)',
        count: waProblems.length,
        severity: 'amber',
        detail: _uniqueTitles(waProblems),
      ));
    }
    if (reProblems.length >= 2) {
      patterns.add(MistakePattern(
        patternName: 'Runtime Error',
        count: reProblems.length,
        severity: 'blue',
        detail: _uniqueTitles(reProblems),
      ));
    }
    if (mleProblems.length >= 2) {
      patterns.add(MistakePattern(
        patternName: 'Memory Limit Exceeded (MLE)',
        count: mleProblems.length,
        severity: 'blue',
        detail: _uniqueTitles(mleProblems),
      ));
    }

    // Sort by count descending
    patterns.sort((a, b) => b.count.compareTo(a.count));

    setState(() => _patterns = patterns);
  }

  String _uniqueTitles(List<String> titles) {
    final unique = titles.toSet().take(3).toList();
    return unique.join(', ');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Monthly solve count
  // ─────────────────────────────────────────────────────────────────────────────
  void _computeMonthlyProgress(StatsProvider stats) {
    final calendar = stats.leetcodeStats?.submissionCalendar ?? {};
    final now = DateTime.now();
    int count = 0;
    for (final entry in calendar.entries) {
      if (entry.key.month == now.month && entry.key.year == now.year) {
        count += entry.value;
      }
    }
    setState(() => _solvedThisMonth = count);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build the WeeklySnapshot (Sun→Sat window)
  // ─────────────────────────────────────────────────────────────────────────────
  WeeklySnapshot _buildWeeklySnapshot(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final subs = lc?.recentSubmissions ?? [];
    final tagStats = lc?.tagStats ?? {};

    // This week: Sunday → Saturday
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    final weekStart = DateTime(sunday.year, sunday.month, sunday.day);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final thisWeekSubs = subs
        .where((s) =>
            !s.timestamp.isBefore(weekStart) &&
            !s.timestamp.isAfter(weekEnd.add(const Duration(days: 1))))
        .toList();

    int easy = 0, medium = 0, hard = 0, solved = 0, totalSubs = 0;
    for (final s in thisWeekSubs) {
      totalSubs++;
      if (s.status.toLowerCase().contains('accept')) {
        solved++;
        final diff = (s.difficulty ?? '').toLowerCase();
        if (diff == 'easy') easy++;
        else if (diff == 'medium') medium++;
        else if (diff == 'hard') hard++;
      }
    }

    // Topics covered this week — infer from accepted problem titles
    final topicsCovered = <String>{};
    for (final s in thisWeekSubs) {
      if (!s.status.toLowerCase().contains('accept')) continue;
      final t = s.title.toLowerCase();
      if (t.contains('tree') || t.contains('trie')) topicsCovered.add('Trees');
      if (t.contains('graph') || t.contains('path') || t.contains('network')) topicsCovered.add('Graphs');
      if (t.contains('dynamic') || t.contains('knapsack') || t.contains('fibonacci')) topicsCovered.add('Dynamic Programming');
      if (t.contains('sort') || t.contains('subarray') || t.contains('prefix')) topicsCovered.add('Arrays');
      if (t.contains('string') || t.contains('palindrome') || t.contains('anagram')) topicsCovered.add('Strings');
      if (t.contains('backtrack') || t.contains('permut') || t.contains('subset')) topicsCovered.add('Backtracking');
      if (t.contains('greedy') || t.contains('jump') || t.contains('interval')) topicsCovered.add('Greedy');
      if (t.contains('bit') || t.contains('xor')) topicsCovered.add('Bit Manipulation');
      if (t.contains('math') || t.contains('prime') || t.contains('gcd')) topicsCovered.add('Math');
    }

    // Also pull top tag stats for supplementary coverage
    final topTags = tagStats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final tag in topTags.take(3)) {
      for (final entry in _topicAliases.entries) {
        if (entry.value.any((a) => a.toLowerCase() == tag.key.toLowerCase())) {
          topicsCovered.add(entry.key);
        }
      }
    }

    return WeeklySnapshot(
      weekNumber: _currentWeekNumber(),
      solvedThisWeek: solved,
      easyThisWeek: easy,
      mediumThisWeek: medium,
      hardThisWeek: hard,
      totalSubmissions: totalSubs,
      streakDelta: lc?.streak ?? 0,
      bestPlatform: _bestPlatform(stats),
      topicsCovered: topicsCovered.toList(),
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Load goals from SharedPreferences
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('coach_goals_v2');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        final goals = list.map((e) => CoachGoal.fromJson(e as Map<String, dynamic>)).toList();
        if (mounted) setState(() => _goals = goals);
      } catch (_) {}
    }
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coach_goals_v2', jsonEncode(_goals.map((g) => g.toJson()).toList()));
  }

  void _addGoal(CoachGoal goal) {
    setState(() => _goals.add(goal));
    _saveGoals();
  }

  void _removeGoal(CoachGoal goal) {
    setState(() => _goals.removeWhere((g) => g.id == goal.id));
    _saveGoals();
  }

  void _showAddGoalSheet(int curSolved, int curRating, int curStreak) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddGoalSheet(
        currentSolved: curSolved,
        currentRating: curRating,
        currentStreak: curStreak,
        onAdd: (goal) {
          _addGoal(goal);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Fetch upcoming Codeforces contest
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _fetchCodeforcesContest() async {
    try {
      final resp = await http.get(
        Uri.parse('https://codeforces.com/api/contest.list?gym=false'),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body);
      final contests = (data['result'] as List?)
          ?.where((c) => c['phase'] == 'BEFORE')
          .toList();
      if (contests != null && contests.isNotEmpty && mounted) {
        final next = contests.first;
        final ts = next['startTimeSeconds'] as int?;
        setState(() {
          _upcomingContest = next['name']?.toString() ?? 'Upcoming Contest';
          _upcomingContestTime = ts != null
              ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
              : null;
        });
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // initState + data loading
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initData());
  }

  Future<void> _initData() async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    final snapshot = _buildSnapshot(stats);

    _computeReadiness(stats);
    _computeMistakePatterns(stats);
    _computeMonthlyProgress(stats);

    final weekly = _buildWeeklySnapshot(stats);
    if (mounted) setState(() => _weeklySnapshot = weekly);

    await Future.wait([
      _loadDailyInsight(snapshot),
      _loadFocusProblems(snapshot, stats),
      _fetchCodeforcesContest(),
      _loadGoals(),
    ]);
  }

  Future<void> _loadDailyInsight(StatsSnapshot snapshot) async {
    if (!mounted) return;
    setState(() { _bannerLoading = true; _bannerError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final key = 'coach_banner_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final ci = prefs.getString('${key}_insight');
      final cn = prefs.getString('${key}_nudge');

      if (ci != null && cn != null && ci.isNotEmpty) {
        if (mounted) setState(() { _bannerInsight = ci; _bannerNudge = cn; _bannerLoading = false; });
        return;
      }

      final result = await InsightService.getDailyInsight(snapshot);
      if (!mounted) return;
      await prefs.setString('${key}_insight', result['insight'] ?? '');
      await prefs.setString('${key}_nudge', result['nudge'] ?? '');
      setState(() { _bannerInsight = result['insight']; _bannerNudge = result['nudge']; _bannerLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _bannerError = 'Couldn\'t load AI insight.'; _bannerLoading = false; });
    }
  }

  Future<void> _loadFocusProblems(StatsSnapshot snapshot, StatsProvider stats) async {
    if (!mounted) return;
    setState(() { _focusLoading = true; _focusError = null; });
    try {
      final recentTopics = _extractRecentTopics(stats);
      final problems = await InsightService.getFocusProblems(
        recentTopics: recentTopics,
        weakTopics: snapshot.topWeakTopics,
        totalSolved: snapshot.totalSolved,
        mediumSolved: snapshot.mediumSolved,
        hardSolved: snapshot.hardSolved,
      );
      if (mounted) setState(() { _focusProblems = problems; _focusLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _focusError = e.toString(); _focusLoading = false; });
    }
  }

  Future<void> _getTip(String patternName) async {
    setState(() => _tipLoadingState[patternName] = true);
    try {
      final tip = await InsightService.getMistakeTip(patternName);
      final idx = _patterns.indexWhere((p) => p.patternName == patternName);
      if (idx != -1 && mounted) {
        setState(() { _patterns[idx].aiTip = tip; _tipLoadingState[patternName] = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _tipLoadingState[patternName] = false);
    }
  }

  Future<void> _generateWeeklyReport() async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    setState(() { _weeklyLoading = true; _weeklyError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final weekNum = _currentWeekNumber();
      final cs = prefs.getString('wk_summary_$weekNum');
      final cf = prefs.getString('wk_focus_$weekNum');
      if (cs != null && cf != null && cs.isNotEmpty) {
        if (mounted) setState(() { _weeklyReport = {'summary': cs, 'focus': cf}; _weeklyLoading = false; });
        return;
      }

      final snapshot = _weeklySnapshot ?? _buildWeeklySnapshot(stats);
      final result = await InsightService.getWeeklyReport(snapshot);
      if (!mounted) return;
      await prefs.setString('wk_summary_$weekNum', result['summary'] ?? '');
      await prefs.setString('wk_focus_$weekNum', result['focus'] ?? '');
      setState(() { _weeklyReport = result; _weeklyLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _weeklyError = e.toString(); _weeklyLoading = false; });
    }
  }

  Future<void> _sendChat(String message) async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    final snapshot = _buildSnapshot(stats);
    setState(() { _chatHistory.add({'role': 'user', 'content': message}); _chatTyping = true; _chatError = null; });
    try {
      final response = await InsightService.getChatResponse(_chatHistory, snapshot);
      if (mounted) setState(() { _chatHistory.add({'role': 'model', 'content': response}); _chatTyping = false; });
    } catch (e) {
      if (mounted) setState(() { _chatError = 'Couldn\'t reach AI coach.'; _chatTyping = false; });
    }
  }

  Future<void> _showTopicTip(BuildContext context, String topic) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Getting AI tip for $topic...'),
        duration: const Duration(seconds: 30),
        action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
      ),
    );
    try {
      final tip = await InsightService.getMistakeTip('$topic problems');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('💡 $topic Tips'),
            content: Text(tip, style: const TextStyle(height: 1.5)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t load tip.')),
        );
      }
    }
  }

  String _bestPlatform(StatsProvider stats) {
    final totals = {
      'LeetCode':   stats.leetcodeStats?.totalSolved ?? 0,
      'Codeforces': stats.codeforcesStats?.totalSolved ?? 0,
      'CodeChef':   stats.codechefStats?.totalSolved ?? 0,
      'HackerRank': stats.hackerrankStats?.totalSolved ?? 0,
    };
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _currentWeekNumber() {
    final now = DateTime.now();
    return ((now.difference(DateTime(now.year, 1, 1)).inDays) / 7).floor() + 1;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = context.watch<StatsProvider>();
    final tagStats = stats.leetcodeStats?.tagStats ?? {};

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_outlined, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 10),
            const Text('AI Insight Coach', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -60, right: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.05),
              ),
            ).animate().fadeIn(duration: 2.seconds),
          ),
          Positioned(
            bottom: 200, left: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.tertiary.withOpacity(0.04),
              ),
            ).animate().fadeIn(duration: 3.seconds),
          ),

          RefreshIndicator(
            onRefresh: _onRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1 ── Daily Insight Banner ─────────────────────────────────
                DailyInsightBanner(
                  insight: _bannerInsight,
                  nudge: _bannerNudge,
                  isLoading: _bannerLoading,
                  errorMessage: _bannerError,
                  onRetry: () => _loadDailyInsight(_buildSnapshot(stats)),
                ),
                const SizedBox(height: 24),

                // 2 ── Skill Gap Chart ──────────────────────────────────────
                _header(context, 'Skill Gap Analysis', Icons.bar_chart_rounded),
                const SizedBox(height: 12),
                SkillGapChart(
                  tagStats: tagStats,
                  onTapTopic: (t) => _showTopicTip(context, t),
                ),
                const SizedBox(height: 24),

                // 3 ── Focus Problems ───────────────────────────────────────
                FocusProblemsCard(
                  problems: _focusProblems,
                  isLoading: _focusLoading,
                  errorMessage: _focusError,
                  onRefresh: () => _loadFocusProblems(_buildSnapshot(stats), stats),
                ),
                const SizedBox(height: 24),

                // 4 ── Mistake Patterns ─────────────────────────────────────
                MistakePatternSection(
                  patterns: _patterns,
                  onGetTip: _getTip,
                  tipLoadingState: _tipLoadingState,
                ),
                const SizedBox(height: 24),

                // 5 ── Progress Forecast (multi-goal) ──────────────────────
                _header(context, 'Progress Forecast', Icons.trending_up_rounded),
                const SizedBox(height: 12),
                ProgressForecastCard(
                  totalSolved: stats.totalSolved,
                  currentRating: (stats.leetcodeStats?.rating ?? 0.0).toInt(),
                  currentStreak: stats.leetcodeStats?.streak ?? 0,
                  solvedThisMonth: _solvedThisMonth,
                  daysElapsed: DateTime.now().day,
                  goals: _goals,
                  onAddGoal: _showAddGoalSheet,
                  onRemoveGoal: _removeGoal,
                ),
                const SizedBox(height: 24),

                // 6 ── Contest Readiness ────────────────────────────────────
                _header(context, 'Contest Readiness', Icons.emoji_events_outlined),
                const SizedBox(height: 12),
                ContestReadinessCard(
                  score: _readinessScore,
                  subScores: _readinessSubScores,
                  upcomingContest: _upcomingContest,
                  upcomingContestTime: _upcomingContestTime,
                ),
                const SizedBox(height: 24),

                // 7 ── Weekly Report Card ───────────────────────────────────
                _header(context, 'Weekly Report', Icons.assessment_outlined),
                const SizedBox(height: 12),
                WeeklyReportCard(
                  report: _weeklyReport,
                  snapshot: _weeklySnapshot ?? _buildWeeklySnapshot(stats),
                  isLoading: _weeklyLoading,
                  errorMessage: _weeklyError,
                  onGenerate: _generateWeeklyReport,
                ),
                const SizedBox(height: 24),

                // 8 ── AI Chat Coach ────────────────────────────────────────
                _header(context, 'AI Chat Coach', Icons.chat_bubble_outline_rounded),
                const SizedBox(height: 12),
                AIChatCoach(
                  history: _chatHistory,
                  onSend: _sendChat,
                  isTyping: _chatTyping,
                  errorMessage: _chatError,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Future<void> _onRefresh() async {
    // Also trigger StatsProvider refresh if needed
    await context.read<StatsProvider>().fetchAllStats();
    await _initData();
  }

  Widget _header(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.55),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
