// lib/services/ai_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  // 🔑 Now using GROQ key instead of Gemini
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // ⏳ Cooldown
  static DateTime? _cooldownUntil;

  // 📡 Status stream
  static final _statusController = StreamController<String>.broadcast();
  static Stream<String> get statusStream => _statusController.stream;

  static void _emit(String msg) {
    debugPrint('[AIService] $msg');
    if (!_statusController.isClosed) _statusController.add(msg);
  }

  // 🔒 Queue system
  static bool _isCalling = false;
  static final _waitQueue = <Completer<void>>[];

  static Future<T> _safeCall<T>(Future<T> Function() fn) async {
    if (_isCalling) {
      final slot = Completer<void>();
      _waitQueue.add(slot);
      await slot.future;
    }
    _isCalling = true;
    try {
      return await fn();
    } finally {
      _isCalling = false;
      if (_waitQueue.isNotEmpty) {
        _waitQueue.removeAt(0).complete();
      }
    }
  }

  static Future<String> _callGemini(
    String prompt, {
    int maxOutputTokens = 1024,
  }) async {
    return _safeCall(() async {
      if (_cooldownUntil != null &&
          DateTime.now().isBefore(_cooldownUntil!)) {
        final secs =
            _cooldownUntil!.difference(DateTime.now()).inSeconds + 1;
        throw Exception('Rate limited. Wait ~$secs seconds.');
      }

      final uri =
          Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      _emit('Calling Groq AI...');

      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: jsonEncode({
                "model": "llama-3.1-8b-instant",
                "messages": [
                  {"role": "user", "content": prompt}
                ],
                "temperature": 0.2,
                "max_tokens": maxOutputTokens,
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices'][0]['message']['content'];

          if (text == null || text.trim().isEmpty) {
            throw Exception('Empty response from Groq.');
          }

          _cooldownUntil = null;
          _emit('Analysis complete ✓');
          return text.trim();
        }

        if (response.statusCode == 429) {
          _cooldownUntil =
              DateTime.now().add(const Duration(seconds: 30));
          throw Exception('Rate limited. Please wait ~30 seconds.');
        }

        throw Exception(
            'Groq API error ${response.statusCode}: ${response.body}');
      } on TimeoutException {
        throw Exception('Request timed out. Try again.');
      } catch (e) {
        rethrow;
      }
    });
  }

  static String _extractJson(String raw) {
    // 1. Remove markdown blocks
    String cleaned = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // 2. Try to find the start and end of a JSON array or object
    final firstRect = cleaned.indexOf('[');
    final lastRect = cleaned.lastIndexOf(']');
    final firstCurly = cleaned.indexOf('{');
    final lastCurly = cleaned.lastIndexOf('}');

    // Prioritize the block that seems most like the outer-most JSON structure
    if (firstRect != -1 && lastRect != -1 && (firstCurly == -1 || firstRect < firstCurly)) {
      if (lastRect > firstRect) {
        return cleaned.substring(firstRect, lastRect + 1);
      }
    } else if (firstCurly != -1 && lastCurly != -1) {
      if (lastCurly > firstCurly) {
        return cleaned.substring(firstCurly, lastCurly + 1);
      }
    }

    return cleaned;
  }

  static Future<Map<String, String>> analyzeResume({
    required String resumeText,
    required String codingProfileData,
  }) async {
    if (_apiKey.isEmpty) throw Exception('Missing GROQ_API_KEY in .env');

    _emit('Preparing resume analysis...');

    final trimmedResume =
        resumeText.length > 3000 ? resumeText.substring(0, 3000) : resumeText;

    final trimmedStats = codingProfileData.length > 600
        ? codingProfileData.substring(0, 600)
        : codingProfileData;

    final prompt = '''
You are a senior technical recruiter. Analyze the resume and candidate stats.
Return ONLY raw JSON.

RESUME: $trimmedResume
STATS: $trimmedStats

JSON structure:
{
  "ats_score": <int>,
  "resume_summary": ["string"],
  "coding_summary": ["string"],
  "recommendations": ["string"]
}''';

    try {
      final raw = await _callGemini(prompt, maxOutputTokens: 1500);
      final cleaned = _extractJson(raw);
      final result = jsonDecode(cleaned) as Map<String, dynamic>;

      String formatList(dynamic field) {
        if (field is List) {
          return field.map((e) => '• $e').join('\n');
        }
        return field.toString().trim();
      }

      final rawScore = (result['ats_score'] as num?)?.toInt() ?? 75;

      return {
        'ats_score': rawScore.clamp(60, 95).toString(),
        'resume_summary': formatList(result['resume_summary'] ?? []),
        'coding_summary': formatList(result['coding_summary'] ?? []),
        'recommendations': formatList(result['recommendations'] ?? []),
      };
    } catch (e) {
      debugPrint('[AIService] analyzeResume error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<List<String>> generateInsights({
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prompt = 'Give 2 short coding insights for: ${jsonEncode(userData)}. Return ONLY JSON array of strings.';
      final raw = await _callGemini(prompt, maxOutputTokens: 200);
      final cleaned = _extractJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is List) return decoded.map((e) => e.toString()).take(2).toList();
      return ['📈 Keep practice consistent.'];
    } catch (e) {
      return ['📈 Keep practice consistent.', '🚀 Try harder problems.'];
    }
  }

  static Future<List<dynamic>> generateStructuredInsights({
    required Map<String, dynamic> userData,
  }) async {
    final prompt = '''
Analyze these coding statistics and return EXACTLY 3 personalized insights.
Return ONLY a raw JSON array of objects. NO conversational text, NO preamble, NO markdown blocks.

Structure:
[
  {
    "id": "unique_id",
    "title": "Short Title",
    "reason": "Why this insight?",
    "impact": "What to do?",
    "confidence": "High/Medium",
    "topic": "Primary Topic",
    "type": "weakness/strength/slowness/errorRate",
    "emoji": "💡"
  }
]

Data: ${jsonEncode(userData)}
''';
    try {
      final raw = await _callGemini(prompt, maxOutputTokens: 800);
      final cleaned = _extractJson(raw);
      return jsonDecode(cleaned) as List<dynamic>;
    } catch (e) {
      debugPrint('[AIService] generateStructuredInsights error: $e');
      rethrow;
    }
  }

  static Future<dynamic> generateActionPlan({
    required String topic,
    required String insightTitle,
    required String insightId,
    required double weaknessLevel,
  }) async {
    final prompt = '''
Generate a 3-step action plan for the topic "$topic" based on the weakness "$insightTitle".
Return ONLY a raw JSON object. NO conversational text.

Structure:
{
  "steps": ["Step 1", "Step 2", "Step 3"],
  "resources": [{"title": "Name", "url": "URL"}],
  "estimatedTime": "2 weeks"
}
''';
    try {
      final raw = await _callGemini(prompt, maxOutputTokens: 500);
      final cleaned = _extractJson(raw);
      return jsonDecode(cleaned);
    } catch (e) {
      debugPrint('[AIService] generateActionPlan error: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> generateRecommendations({
    required List<dynamic> insights,
    required Map<String, dynamic> topicStats,
    required int totalSolved,
    required Map<String, int> difficultyBreakdown,
    required List<dynamic> recentSubmissions,
  }) async {
    final prompt = '''
Generate 3 personalized coding recommendations based on recent performance.
Return ONLY a raw JSON array of objects. NO conversational text.

Structure:
[
  {
    "id": "rec_id",
    "title": "Actionable Title",
    "description": "Short description",
    "type": "focus/improve/challenge/balance",
    "topic": "Topic Name",
    "priority": 1
  }
]

Context:
Total Solved: $totalSolved
Insights: ${jsonEncode(insights)}
Recent Submissions: ${jsonEncode(recentSubmissions)}
''';
    try {
      final raw = await _callGemini(prompt, maxOutputTokens: 600);
      final cleaned = _extractJson(raw);
      return jsonDecode(cleaned) as List<dynamic>;
    } catch (e) {
      debugPrint('[AIService] generateRecommendations error: $e');
      rethrow;
    }
  }

  static Future<List<String>> classifyProblem(String title) async {
    final prompt = 'Classify "$title" into 1-3 topics. Return ONLY a raw JSON array of strings. NO text.';
    try {
      final raw = await _callGemini(prompt, maxOutputTokens: 100);
      final cleaned = _extractJson(raw);
      final decoded = jsonDecode(cleaned);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
      return ['General'];
    } catch (e) {
      return ['General'];
    }
  }
}
