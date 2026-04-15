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
  static Future<Map<String, String>> getDailyInsight(
    StatsSnapshot stats, {
    List<String> recentProblemNames = const [],
  }) async {
    final weakestTopic = stats.topWeakTopics.isNotEmpty ? stats.topWeakTopics.first : 'general problem solving';
    final recentActivity = recentProblemNames.isNotEmpty
        ? 'Their most recently solved problems (last 7 days): ${recentProblemNames.take(6).join(", ")}.'
        : 'No recent problems available.';

    final prompt =
        'You are an expert competitive programming coach. A programmer has these exact stats today:\n'
        '- Streak: ${stats.streak} days (${stats.streak < 3 ? "at risk" : "maintained"})\n'
        '- Total solved: ${stats.totalSolved} (Easy: ${stats.easySolved}, Medium: ${stats.mediumSolved}, Hard: ${stats.hardSolved})\n'
        '- Problems solved last 7 days: ${stats.recentSubmissionCount}\n'
        '- Weakest topic right now: $weakestTopic\n'
        '- Active platforms: ${stats.platforms.join(", ")}\n'
        '- $recentActivity\n\n'
        'TASK:\n'
        '1. Write ONE sentence of insight about their performance based on the recent problems above.\n'
        '2. Write NUDGE: followed by ONE specific task for TODAY. The nudge MUST:\n'
        '   - Be directly related to their recent activity (reference patterns from $recentActivity)\n'
        '   - Suggest the natural NEXT step (e.g., if they solved backtracking, suggest optimizing with pruning)\n'
        '   - Name a specific pattern or technique — NOT a vague topic\n'
        '   - NOT suggest trees/graphs/DP unless those appear in their recent activity\n'
        'No greetings. No other text.';

    final response = await _callGroq(prompt, maxTokens: 200, temperature: 0.75);
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
    required List<String> recentProblemNames,
    required int totalSolved,
    required int mediumSolved,
    required int hardSolved,
  }) async {
    final topics = recentTopics.isNotEmpty ? recentTopics : weakTopics;
    final prompt = 'You are a competitive programming coach. '
        'The programmer recently worked on these topics: ${topics.join(", ")}. '
        'They recently solved these specific problems: ${recentProblemNames.join(", ")}. '
        'Their weak areas are: ${weakTopics.join(", ")}. '
        'They have solved $totalSolved problems total ($mediumSolved medium, $hardSolved hard). '
        'Suggest exactly 3 problems that the student has NOT solved yet. '
        '\nCRITICAL CONSTRAINTS:\n'
        '1. DO NOT suggest over-popular or "classic" problems like "Two Sum", "Container with Most Water", "Reverse Integer", or other top 100 liked items unless they are hard and very relevant.\n'
        '2. Prioritize niche but high-quality problems that build on their recent work but are slightly harder.\n'
        '3. Ensure the problems are from distinct topics (e.g., if they solved a Tree problem, suggest a Graph problem or a related DP problem).\n'
        '4. Respond ONLY with a valid JSON array, no markdown, no preamble:\n'
        '[{"problemName":"...","platform":"LeetCode|Codeforces|CodeChef","difficulty":"Easy|Medium|Hard",'
        '"topicTag":"...","aiReason":"Explain how this builds on their recent solve of [Recent Problem Name] but adds a new complexity"}]';

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
        : 'general problem solving';

    const topicProgressions = {
      'Arrays': 'Sliding Window, Prefix Sums, or Two-Pointer patterns',
      'Strings': 'String Hashing, KMP pattern matching, or Trie-based problems',
      'Dynamic Programming': 'interval DP, bitmask DP, or DP on trees',
      'Graphs': 'Dijkstra, topological sort, or strongly connected components',
      'Backtracking': 'pruning optimization, constraint propagation, or N-Queens variants',
      'Greedy': 'interval scheduling, activity selection, or fractional knapsack problems',
      'Trees': 'LCA problems, tree DP, or serialization of trees',
      'Math': 'modular arithmetic, combinatorics, or number theory',
      'Bit Manipulation': 'XOR tricks, bit masking, or subset enumeration',
    };

    final nextSteps = stats.topicsCovered
        .where((t) => topicProgressions.containsKey(t))
        .map((t) => '- Since they did $t → suggest ${topicProgressions[t]}')
        .join('\n');

    final prompt = 'Analyze this programmer\'s EXACT performance this week:\n'
        '- Solved: ${stats.solvedThisWeek} problems '
        '(Easy: ${stats.easyThisWeek}, Medium: ${stats.mediumThisWeek}, Hard: ${stats.hardThisWeek})\n'
        '- Accuracy: ${stats.solvedThisWeek}/${stats.totalSubmissions} accepted\n'
        '- Topics actually covered this week: $topicsList\n'
        '- Streak change: ${stats.streakDelta}\n'
        '- Platform: ${stats.bestPlatform}\n\n'
        'TOPIC PROGRESSION HINTS (use these, don\'t copy verbatim):\n'
        '${nextSteps.isNotEmpty ? nextSteps : "- No specific topics detected, suggest foundational patterns"}\n\n'
        'YOUR TASK:\n'
        'RECAP: Write 1 sentence about what they achieved. Be specific about $topicsList.\n'
        'PLAN: Write a 3-step next-week plan. Each step must be concrete (name a pattern or problem type). '
        'DO NOT repeat the same topics from this week unless they need more practice. '
        'DO NOT mention "Trees or Graphs" unless those were actually covered.\n'
        'RESPOND ONLY with RECAP: and PLAN: lines. No other text.';

    final response = await _callGroq(prompt, maxTokens: 450, temperature: 0.6);
    final lines = response.split('\n');
    String summary = '';
    String plan = '';
    
    for (var line in lines) {
      if (line.toUpperCase().startsWith('RECAP:')) {
        summary = line.substring(6).trim();
      } else if (line.toUpperCase().startsWith('PLAN:')) {
        plan = line.substring(5).trim();
      } else if (plan.isNotEmpty && line.trim().isNotEmpty) {
        plan += '\n${line.trim()}'; // collect multi-line plan items
      }
    }

    if (summary.isEmpty) summary = response;
    return {'summary': summary, 'focus': plan};
  }

  // ── Chat Coach ──────────────────────────────────────────────────────────────
  static Future<String> getChatResponse(
    List<Map<String, String>> history,
    StatsSnapshot stats, {
    List<String> recentProblemNames = const [],
  }) async {
    if (_apiKey.isEmpty) throw InsightException('GROQ_API_KEY not found in .env');

    final recentContext = recentProblemNames.isNotEmpty
        ? 'Recently solved problems: ${recentProblemNames.take(8).join(", ")}.'
        : 'No recent problem history available.';

    final systemMessage = 'You are an expert competitive programming coach in the CodeSphere app. '
        'USER PROFILE:\n'
        '- Total solved: ${stats.totalSolved} (Easy: ${stats.easySolved}, Medium: ${stats.mediumSolved}, Hard: ${stats.hardSolved})\n'
        '- Streak: ${stats.streak} days\n'
        '- Weakest topics: ${stats.topWeakTopics.take(3).join(", ")}\n'
        '- $recentContext\n\n'
        'COACHING RULES:\n'
        '1. Give advice BASED on the above recent activity. DO NOT suggest Trees/Graphs unless the user specifically asks or their weak topic is Trees/Graphs.\n'
        '2. Reference their actual recent problems when giving advice.\n'
        '3. Suggest specific problem names, patterns (e.g., Sliding Window, Two Pointers), or LeetCode problem numbers.\n'
        '4. Keep responses under 120 words. If asked for a plan, give bullet points.';

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


