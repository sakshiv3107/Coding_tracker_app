// lib/screens/ai_insight_coach_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/stats_provider.dart';
//import '../providers/auth_provider.dart';
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
  // ── Daily Insight state ──────────────────────────────────────────────────
  String? _bannerInsight;
  String? _bannerNudge;
  bool _bannerLoading = false;
  String? _bannerError;

  // ── Focus Problems state ─────────────────────────────────────────────────
  List<FocusProblem>? _focusProblems;
  bool _focusLoading = false;
  String? _focusError;

  // ── Mistake Patterns state ───────────────────────────────────────────────
  List<MistakePattern> _patterns = [];
  final Map<String, bool> _tipLoadingState = {};

  // ── Progress Forecast state ──────────────────────────────────────────────
  String? _goalTitle;
  int? _goalTarget;
  int _solvedThisMonth = 0;

  // ── Contest state ────────────────────────────────────────────────────────
  String? _upcomingContest;
  DateTime? _upcomingContestTime;

  // ── Weekly report state ──────────────────────────────────────────────────
  Map<String, String>? _weeklyReport;
  bool _weeklyLoading = false;
  String? _weeklyError;

  // ── AI Chat state ────────────────────────────────────────────────────────
  final List<Map<String, String>> _chatHistory = [];
  bool _chatTyping = false;
  String? _chatError;

  // ── Computed readiness score ──────────────────────────────────────────────
  int _readinessScore = 0;
  Map<String, int> _readinessSubScores = {
    'Consistency': 0, 'Breadth': 0, 'Mix': 0, 'Recent': 0
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build StatsSnapshot from provider
  // ─────────────────────────────────────────────────────────────────────────
  // Alias map: display name → LeetCode API tag names
  static const _topicAliases = <String, List<String>>{
    'Arrays':            ['Array', 'Arrays'],
    'Strings':           ['String', 'Strings'],
    'Trees':             ['Tree', 'Binary Tree', 'Trees'],
    'Graphs':            ['Graph', 'Graphs', 'Graph Theory'],
    'Dynamic Programming': ['Dynamic Programming'],
    'Greedy':            ['Greedy'],
    'Backtracking':      ['Backtracking'],
    'Segment Tree':      ['Segment Tree'],
    'Bit Manipulation':  ['Bit Manipulation'],
    'Math':              ['Math', 'Mathematics'],
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
        if (entry.key.toLowerCase() == alias.toLowerCase()) {
          total += entry.value;
        }
      }
    }
    return total;
  }

  StatsSnapshot _buildSnapshot(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final tagStats = lc?.tagStats ?? {};

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

    final topWeakTopics = weakTopics.take(3).map((e) => e.key).toList();

    // Count recent submissions (last 7 days)
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
      topWeakTopics: topWeakTopics.isEmpty ? ['Dynamic Programming', 'Graph', 'Trees'] : topWeakTopics,
      recentSubmissionCount: recentCount,
      platforms: platforms,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Compute contest readiness score client-side
  // ─────────────────────────────────────────────────────────────────────────
  void _computeReadiness(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final total = stats.totalSolved;
    final streak = lc?.streak ?? 0;
    final medium = lc?.medium ?? 0;
    final hard = lc?.hard ?? 0;
    final tagStats = lc?.tagStats ?? {};

    // Consistency: streak/30 * 25
    final consistency = ((streak / 30) * 25).clamp(0.0, 25.0).toInt();

    // Topic breadth: % of topics above threshold * 25
    int topicsAboveThreshold = 0;
    for (final topic in _topicAliases.keys) {
      final threshold = _topicThresholds[topic] ?? 16;
      final solved = _resolveTag(tagStats, topic);
      final cutoff = (threshold * 0.4).ceil();
      if (solved >= cutoff) topicsAboveThreshold++;
    }
    final breadth = ((topicsAboveThreshold / _topicAliases.length) * 25).toInt();

    // Difficulty mix: (medium + hard) / total * 25
    final mix = total > 0 ? (((medium + hard) / total) * 25).toInt() : 0;

    // Recent activity: recent7 / 7 * 25
    final recentSubs = lc?.recentSubmissions ?? [];
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent7 = recentSubs.where((s) => s.timestamp.isAfter(sevenDaysAgo)).length;
    final recency = ((recent7 / 7) * 25).clamp(0.0, 25.0).toInt();

    setState(() {
      _readinessSubScores = {
        'Consistency': consistency,
        'Breadth': breadth,
        'Mix': mix,
        'Recent': recency,
      };
      _readinessScore = (consistency + breadth + mix + recency).clamp(0, 100);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Compute mistake patterns from recent submissions
  // ─────────────────────────────────────────────────────────────────────────
  void _computeMistakePatterns(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final subs = lc?.recentSubmissions ?? [];
    if (subs.isEmpty) return;

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentSubs = subs.where((s) => s.timestamp.isAfter(thirtyDaysAgo)).toList();

    int tleCount = 0, waCount = 0, reCount = 0;
    for (final s in recentSubs) {
      final status = s.status.toLowerCase();
      if (status.contains('time limit')) tleCount++;
      if (status.contains('wrong answer')) waCount++;
      if (status.contains('runtime error')) reCount++;
    }

    final newPatterns = <MistakePattern>[];
    if (tleCount > 1) {newPatterns.add(MistakePattern(
      patternName: 'Time Limit Exceeded (TLE)',
      count: tleCount, severity: 'red',
    ));}
    if (waCount > 1) {newPatterns.add(MistakePattern(
      patternName: 'Wrong Answer (WA)',
      count: waCount, severity: 'amber',
    ));}
    if (reCount > 1) {newPatterns.add(MistakePattern(
      patternName: 'Runtime Error',
      count: reCount, severity: 'blue',
    ));}

    setState(() => _patterns = newPatterns);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Compute monthly solve count
  // ─────────────────────────────────────────────────────────────────────────
  void _computeMonthlyProgress(StatsProvider stats) {
    final lc = stats.leetcodeStats;
    final calendar = lc?.submissionCalendar ?? {};
    final now = DateTime.now();
    int count = 0;
    for (final entry in calendar.entries) {
      if (entry.key.month == now.month && entry.key.year == now.year) {
        count += entry.value;
      }
    }
    setState(() => _solvedThisMonth = count);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fetch upcoming Codeforces contest
  // ─────────────────────────────────────────────────────────────────────────
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
      if (contests != null && contests.isNotEmpty) {
        final next = contests.first;
        final name = next['name']?.toString() ?? 'Upcoming Contest';
        final ts = next['startTimeSeconds'] as int?;
        if (mounted && ts != null) {
          setState(() {
            _upcomingContest = name;
            _upcomingContestTime = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          });
        }
      }
    } catch (_) {
      // Silently omit on failure
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load goal from SharedPreferences
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString('coach_goal_title');
    final target = prefs.getInt('coach_goal_target');
    if (mounted) setState(() { _goalTitle = title; _goalTarget = target; });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main init: triggers all data loading
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _initData() async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    final snapshot = _buildSnapshot(stats);

    _computeReadiness(stats);
    _computeMistakePatterns(stats);
    _computeMonthlyProgress(stats);

    await Future.wait([
      _loadDailyInsight(snapshot),
      _loadFocusProblems(snapshot),
      _fetchCodeforcesContest(),
      _loadGoal(),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load daily insight (with SharedPreferences caching by date)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadDailyInsight(StatsSnapshot snapshot) async {
    if (!mounted) return;
    setState(() { _bannerLoading = true; _bannerError = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final key = 'insight_banner_${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final cachedInsight = prefs.getString('${key}_insight');
      final cachedNudge  = prefs.getString('${key}_nudge');

      if (cachedInsight != null && cachedNudge != null) {
        {if (mounted) setState(() {
          _bannerInsight = cachedInsight;
          _bannerNudge   = cachedNudge;
          _bannerLoading = false;
        });}
        return;
      }

      final result = await InsightService.getDailyInsight(snapshot);
      if (!mounted) return;

      await prefs.setString('${key}_insight', result['insight'] ?? '');
      await prefs.setString('${key}_nudge',   result['nudge']   ?? '');

      setState(() {
        _bannerInsight = result['insight'];
        _bannerNudge   = result['nudge'];
        _bannerLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _bannerError   = 'Couldn\'t load AI insight. Tap retry.';
        _bannerLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load focus problems
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _loadFocusProblems(StatsSnapshot? snapshot) async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    final snap = snapshot ?? _buildSnapshot(stats);

    setState(() { _focusLoading = true; _focusError = null; });
    try {
      final problems = await InsightService.getFocusProblems(snap);
      if (mounted) setState(() { _focusProblems = problems; _focusLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _focusError   = e.toString();
        _focusLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get coaching tip (lazy call when user taps "Get tip")
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _getTip(String patternName) async {
    setState(() => _tipLoadingState[patternName] = true);
    try {
      final tip = await InsightService.getMistakeTip(patternName);
      final idx = _patterns.indexWhere((p) => p.patternName == patternName);
      if (idx != -1 && mounted) {
        setState(() {
          _patterns[idx].aiTip = tip;
          _tipLoadingState[patternName] = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _tipLoadingState[patternName] = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Generate weekly report
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _generateWeeklyReport() async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    final lc = stats.leetcodeStats;

    setState(() { _weeklyLoading = true; _weeklyError = null; });

    try {
      final prefs  = await SharedPreferences.getInstance();
      final weekNum = _currentWeekNumber();

      final cachedSummary = prefs.getString('weekly_summary_$weekNum');
      final cachedFocus   = prefs.getString('weekly_focus_$weekNum');

      if (cachedSummary != null && cachedFocus != null) {
        if (mounted) setState(() {
          _weeklyReport  = {'summary': cachedSummary, 'focus': cachedFocus};
          _weeklyLoading = false;
        });
        return;
      }

      final snapshot = WeeklySnapshot(
        weekNumber:    weekNum,
        solvedThisWeek: _solvedThisMonth,
        easyThisWeek:   0,
        mediumThisWeek: 0,
        hardThisWeek:   0,
        streakDelta:    lc?.streak ?? 0,
        bestPlatform:   _bestPlatform(stats),
      );

      final result = await InsightService.getWeeklyReport(snapshot);
      if (!mounted) return;

      await prefs.setString('weekly_summary_$weekNum', result['summary'] ?? '');
      await prefs.setString('weekly_focus_$weekNum',   result['focus']   ?? '');

      setState(() {
        _weeklyReport  = result;
        _weeklyLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _weeklyError   = e.toString();
        _weeklyLoading = false;
      });
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
    final startOfYear = DateTime(now.year, 1, 1);
    return ((now.difference(startOfYear).inDays) / 7).floor() + 1;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Chat send
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _sendChat(String message) async {
    if (!mounted) return;
    final stats = context.read<StatsProvider>();
    final snapshot = _buildSnapshot(stats);

    setState(() {
      _chatHistory.add({'role': 'user', 'content': message});
      _chatTyping   = true;
      _chatError    = null;
    });

    try {
      final response = await InsightService.getChatResponse(_chatHistory, snapshot);
      if (mounted) setState(() {
        _chatHistory.add({'role': 'model', 'content': response});
        _chatTyping = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _chatError  = 'Couldn\'t reach AI coach. Check your connection.';
        _chatTyping = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Goal selection bottom sheet
  // ─────────────────────────────────────────────────────────────────────────
  void _showGoalPicker() {
    final presetGoals = [
      ('Top 10% on LeetCode', 500),
      ('Top 5% on LeetCode', 1000),
      ('Solve 100 Problems', 100),
      ('Solve 300 Problems', 300),
      ('Reach 1800+ Rating', 1800),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Set Your Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ...presetGoals.map((goal) => ListTile(
                title: Text(goal.$1),
                trailing: const Icon(Icons.chevron_right_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('coach_goal_title',  goal.$1);
                  await prefs.setInt('coach_goal_target',    goal.$2);
                  if (mounted) setState(() { _goalTitle = goal.$1; _goalTarget = goal.$2; });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final stats  = context.watch<StatsProvider>();
    final tagStats = stats.leetcodeStats?.tagStats ?? {};
    final daysElapsed = DateTime.now().day;

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
                color: theme.colorScheme.primary.withOpacity(0.06),
              ),
            ).animate().fadeIn(duration: 2.seconds).scale(begin: const Offset(0.4, 0.4)),
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

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Daily Banner ──────────────────────────────────────────
                DailyInsightBanner(
                  insight: _bannerInsight,
                  nudge: _bannerNudge,
                  isLoading: _bannerLoading,
                  errorMessage: _bannerError,
                  onRetry: () {
                    final snap = _buildSnapshot(stats);
                    _loadDailyInsight(snap);
                  },
                ),
                const SizedBox(height: 24),

                // ── 2. Skill Gap Chart ────────────────────────────────────────
                _sectionHeader(context, 'Skill Gap Analysis', Icons.bar_chart_rounded),
                const SizedBox(height: 12),
                SkillGapChart(
                  tagStats: tagStats,
                  onTapTopic: (topic) => _showTopicTip(context, topic, stats),
                ),
                const SizedBox(height: 24),

                // ── 3. Focus Problems ─────────────────────────────────────────
                FocusProblemsCard(
                  problems: _focusProblems,
                  isLoading: _focusLoading,
                  errorMessage: _focusError,
                  onRefresh: () => _loadFocusProblems(null),
                ),
                const SizedBox(height: 24),

                // ── 4. Mistake Patterns ───────────────────────────────────────
                MistakePatternSection(
                  patterns: _patterns,
                  onGetTip: _getTip,
                  tipLoadingState: _tipLoadingState,
                ),
                const SizedBox(height: 24),

                // ── 5. Progress Forecast ──────────────────────────────────────
                _sectionHeader(context, 'Progress Forecast', Icons.trending_up_rounded),
                const SizedBox(height: 12),
                ProgressForecastCard(
                  totalSolved:    stats.totalSolved,
                  solvedThisMonth: _solvedThisMonth,
                  daysElapsed:    daysElapsed,
                  currentGoalTitle: _goalTitle,
                  currentGoalTarget: _goalTarget,
                  onSelectGoal:   _showGoalPicker,
                ),
                const SizedBox(height: 24),

                // ── 6. Contest Readiness ──────────────────────────────────────
                _sectionHeader(context, 'Contest Readiness', Icons.emoji_events_outlined),
                const SizedBox(height: 12),
                ContestReadinessCard(
                  score:             _readinessScore,
                  subScores:         _readinessSubScores,
                  upcomingContest:   _upcomingContest,
                  upcomingContestTime: _upcomingContestTime,
                ),
                const SizedBox(height: 24),

                // ── 7. Weekly Report ──────────────────────────────────────────
                _sectionHeader(context, 'Weekly Report Card', Icons.assessment_outlined),
                const SizedBox(height: 12),
                WeeklyReportCard(
                  report: _weeklyReport,
                  snapshot: WeeklySnapshot(
                    weekNumber:    _currentWeekNumber(),
                    solvedThisWeek: _solvedThisMonth,
                    easyThisWeek:   stats.leetcodeStats?.easy ?? 0,
                    mediumThisWeek: stats.leetcodeStats?.medium ?? 0,
                    hardThisWeek:   stats.leetcodeStats?.hard ?? 0,
                    streakDelta:    stats.leetcodeStats?.streak ?? 0,
                    bestPlatform:   _bestPlatform(stats),
                  ),
                  isLoading: _weeklyLoading,
                  errorMessage: _weeklyError,
                  onGenerate: _generateWeeklyReport,
                ),
                const SizedBox(height: 24),

                // ── 8. AI Chat Coach ──────────────────────────────────────────
                _sectionHeader(context, 'AI Chat Coach', Icons.chat_bubble_outline_rounded),
                const SizedBox(height: 12),
                AIChatCoach(
                  history:      _chatHistory,
                  onSend:       _sendChat,
                  isTyping:     _chatTyping,
                  errorMessage: _chatError,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Show topic AI tip via snackbar (lazy Gemini call)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showTopicTip(BuildContext context, String topic, StatsProvider stats) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Getting AI tip for $topic...', style: const TextStyle(fontSize: 12)),
        duration: const Duration(seconds: 60),
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
            title: Text('💡 $topic Tips', style: const TextStyle(fontSize: 16)),
            content: Text(tip, style: const TextStyle(height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t load tip. Check your connection.')),
        );
      }
    }
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
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
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
