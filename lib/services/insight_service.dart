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

  // ── Strip markdown fences from JSON responses ───────────────────────────────
  static String _stripFences(String raw) {
    return raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
  }

  // ── Extract first JSON array from raw text ──────────────────────────────────
  static String _extractJson(String raw) {
    final cleaned = _stripFences(raw);
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

  // ── Focus Problems ──────────────────────────────────────────────────────────
  static Future<List<FocusProblem>> getFocusProblems(StatsSnapshot stats) async {
    final prompt = 'You are a competitive programming coach. '
        'The programmer\'s weak topics are: ${stats.topWeakTopics.join(", ")}. '
        'They have solved ${stats.totalSolved} problems total '
        '(${stats.mediumSolved} medium, ${stats.hardSolved} hard). '
        'Suggest exactly 3 problems to practice today. '
        'Respond ONLY with a valid JSON array, no markdown, no explanation:\n'
        '[{"problemName":"...","platform":"LeetCode|Codeforces|CodeChef","difficulty":"Easy|Medium|Hard",'
        '"topicTag":"...","aiReason":"one sentence why this problem","url":"direct problem URL"}]';

    final response = await _callGroq(prompt, maxTokens: 600, temperature: 0.6);
    try {
      final jsonStr = _extractJson(response);
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((item) => FocusProblem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[InsightService] JSON Parse Error: $e\nResponse: $response');
      throw InsightException('Couldn\'t parse AI suggestions.');
    }
  }

  // ── Mistake Tip ─────────────────────────────────────────────────────────────
  static Future<String> getMistakeTip(String patternName) async {
    final prompt = 'A competitive programmer keeps hitting $patternName errors in their submissions. '
        'Give one specific, actionable technique to fix this in 2–3 sentences. Be direct and technical.';
    return await _callGroq(prompt, maxTokens: 200, temperature: 0.7);
  }

  // ── Weekly Report ───────────────────────────────────────────────────────────
  static Future<Map<String, String>> getWeeklyReport(WeeklySnapshot stats) async {
    final prompt = 'A programmer solved ${stats.solvedThisWeek} problems this week '
        '(Easy:${stats.easyThisWeek}, Medium:${stats.mediumThisWeek}, Hard:${stats.hardThisWeek}). '
        'Their streak changed by ${stats.streakDelta} days. Best platform: ${stats.bestPlatform}. '
        'Write a 3-sentence weekly performance summary, then on a new line write: '
        'FOCUS: followed by one specific recommendation for next week in 15 words or fewer.';

    final response = await _callGroq(prompt, maxTokens: 250, temperature: 0.8);
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

    final systemMessage = 'You are an expert competitive programming coach embedded in the '
        'CodeSphere analytics app. The user\'s stats are: '
        'total solved: ${stats.totalSolved}, streak: ${stats.streak} days, '
        'easy: ${stats.easySolved}, medium: ${stats.mediumSolved}, hard: ${stats.hardSolved}, '
        'weak topics: ${stats.topWeakTopics.join(", ")}. '
        'Give concise, actionable advice. When suggesting problems, name specific '
        'LeetCode/Codeforces problems. Keep responses under 150 words unless the user asks for a detailed plan.';

    // Build messages array with system prompt  
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
        throw InsightException('AI is rate-limited. Please wait a moment and retry.');
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
