// lib/services/insight_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/insight_model.dart';

class InsightException implements Exception {
  final String message;
  InsightException(this.message);
  @override
  String toString() => message;
}

class InsightService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  // ── Core Groq caller ────────────────────────────────────────────────────────
  static Future<String> _callGroq(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    if (_apiKey.isEmpty) {
      throw InsightException('GROQ_API_KEY not found in .env');
    }
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': temperature,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String? ?? '';
        if (text.trim().isEmpty) throw InsightException('Empty response from AI.');
        return text.trim();
      }
      if (response.statusCode == 429) {
        throw InsightException('AI is rate-limited. Please wait and retry.');
      }
      debugPrint('[InsightService] Error ${response.statusCode}: ${response.body}');
      throw InsightException('Couldn\'t reach AI coach. Check your connection.');
    } on TimeoutException {
      throw InsightException('Request timed out. Please try again.');
    } on InsightException {
      rethrow;
    } catch (e) {
      debugPrint('[InsightService] Exception: $e');
      throw InsightException('Couldn\'t reach AI coach. Check your connection.');
    }
  }

  static String _extractJson(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final firstBracket = cleaned.indexOf('[');
    final lastBracket = cleaned.lastIndexOf(']');
    if (firstBracket != -1 && lastBracket > firstBracket) {
      return cleaned.substring(firstBracket, lastBracket + 1);
    }
    return cleaned;
  }

  // ── Daily Insight ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> getDailyInsight(StatsSnapshot stats) async {
    final prompt = 'You are a coding coach. A competitive programmer has these stats: '
        'streak=${stats.streak} days, total solved=${stats.totalSolved} '
        '(Easy:${stats.easySolved}, Medium:${stats.mediumSolved}, Hard:${stats.hardSolved}), '
        'weakest topics: ${stats.topWeakTopics.join(", ")}, '
        'problems solved last 7 days: ${stats.recentSubmissionCount}. '
        'Write exactly 2 sentences of personalized insight about their current state and what needs attention. '
        'Then on a new line write: NUDGE: followed by an actionable recommendation in 12 words or fewer. No other text.';

    final response = await _callGroq(prompt, maxTokens: 200, temperature: 0.8);
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();

    String insight = '';
    String nudge = '';
    for (var line in lines) {
      if (line.trim().toUpperCase().startsWith('NUDGE:')) {
        nudge = line.trim().substring(6).trim();
      } else {
        insight = insight.isEmpty ? line.trim() : '$insight ${line.trim()}';
      }
    }
    return {'insight': insight, 'nudge': nudge};
  }

  // ── Focus Problems — based on RECENT submission topics ──────────────────────
  static Future<List<FocusProblem>> getFocusProblems({
    required List<String> recentTopics,
    required List<String> weakTopics,
    required int totalSolved,
    required int mediumSolved,
    required int hardSolved,
  }) async {
    final topics = recentTopics.isNotEmpty ? recentTopics : weakTopics;
    final prompt = 'You are a competitive programming coach. '
        'The programmer recently worked on: ${topics.join(", ")}. '
        'Their weak areas are: ${weakTopics.join(", ")}. '
        'They have solved $totalSolved problems total ($mediumSolved medium, $hardSolved hard). '
        'Suggest exactly 3 problems that the student has NOT solved yet. '
        'Pick problems from distinct topics (e.g., one from DP, one from Graph, one from Arrays). '
        'Respond ONLY with a valid JSON array, no markdown, no preamble:\n'
        '[{"problemName":"...","platform":"LeetCode|Codeforces|CodeChef","difficulty":"Easy|Medium|Hard",'
        '"topicTag":"...","aiReason":"one sentence why this specific problem fits their recent work and pushes them"}]';

    final response = await _callGroq(prompt, maxTokens: 600, temperature: 0.5);
    try {
      final List<dynamic> list = jsonDecode(_extractJson(response));
      return list.map((item) => FocusProblem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[InsightService] JSON Parse Error: $e\nResponse: $response');
      throw InsightException('Couldn\'t parse AI suggestions.');
    }
  }

  // ── Mistake Tip (topic-specific) ────────────────────────────────────────────
  static Future<String> getMistakeTip(String errorType) async {
    final prompt = 'A competitive programmer is repeatedly getting $errorType. '
        'Give one precise, actionable debugging or coding technique to fix this. '
        '2-3 sentences max. Include a specific example or pattern to watch for.';
    return await _callGroq(prompt, maxTokens: 180, temperature: 0.6);
  }

  // ── Weekly Report ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> getWeeklyReport(WeeklySnapshot stats) async {
    final topicsList = stats.topicsCovered.isNotEmpty
        ? stats.topicsCovered.join(', ')
        : 'various topics';
    final prompt = 'A programmer this week (Sun–Sat): '
        'solved ${stats.solvedThisWeek} problems '
        '(Easy:${stats.easyThisWeek}, Medium:${stats.mediumThisWeek}, Hard:${stats.hardThisWeek}), '
        'made ${stats.totalSubmissions} total submissions, '
        'covered topics: $topicsList, '
        'streak: ${stats.streakDelta} days, best platform: ${stats.bestPlatform}. '
        'Write a 2-sentence performance summary evaluating their week. '
        'Then on a new line write: FOCUS: followed by one specific goal for next week in 15 words or fewer.';

    final response = await _callGroq(prompt, maxTokens: 200, temperature: 0.7);
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty).toList();

    String summary = '';
    String focus = '';
    for (var line in lines) {
      if (line.trim().toUpperCase().startsWith('FOCUS:')) {
        focus = line.trim().substring(6).trim();
      } else {
        summary = summary.isEmpty ? line.trim() : '$summary ${line.trim()}';
      }
    }
    return {'summary': summary, 'focus': focus};
  }

  // ── Chat Coach ──────────────────────────────────────────────────────────────
  static Future<String> getChatResponse(
    List<Map<String, String>> history,
    StatsSnapshot stats,
  ) async {
    if (_apiKey.isEmpty) throw InsightException('GROQ_API_KEY not found in .env');

    final systemMessage = 'You are an expert competitive programming coach in the '
        'CodeSphere analytics app. User stats: '
        'total solved: ${stats.totalSolved}, streak: ${stats.streak} days, '
        'easy: ${stats.easySolved}, medium: ${stats.mediumSolved}, hard: ${stats.hardSolved}, '
        'weak topics: ${stats.topWeakTopics.join(", ")}. '
        'Be concise and actionable. Name specific LeetCode/Codeforces problems when suggesting. '
        'Keep responses under 150 words unless a detailed plan is requested.';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemMessage},
      ...history.map((m) => {
        'role': m['role'] == 'model' ? 'assistant' : 'user',
        'content': m['content']!,
      }),
    ];

    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.8,
              'max_tokens': 300,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices']?[0]?['message']?['content']?.toString().trim()
            ?? 'I encountered an error. Please try again.';
      }
      if (response.statusCode == 429) {
        throw InsightException('AI is rate-limited. Please wait a moment.');
      }
      throw InsightException('Couldn\'t reach AI coach.');
    } on TimeoutException {
      throw InsightException('Request timed out. Please try again.');
    } on InsightException {
      rethrow;
    } catch (e) {
      debugPrint('[InsightService] Chat Exception: $e');
      throw InsightException('Couldn\'t reach AI coach. Check your connection.');
    }
  }
}
