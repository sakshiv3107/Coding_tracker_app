import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  // 🔑 Now using GROQ key instead of Gemini
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  // ⏳ Cooldown (reused for Groq rate limits)
  static DateTime? _cooldownUntil;

  // 📡 Status stream (unchanged)
  static final _statusController = StreamController<String>.broadcast();
  static Stream<String> get statusStream => _statusController.stream;

  static void _emit(String msg) {
    debugPrint('[AIService] $msg');
    if (!_statusController.isClosed) _statusController.add(msg);
  }

  // 🔒 Queue system (unchanged)
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

  // ─────────────────────────────────────────────────────────
  // 🔥 CORE CALL (NOW USING GROQ)
  // ─────────────────────────────────────────────────────────
  static Future<String> _callGemini(
    String prompt, {
    int maxOutputTokens = 1024,
  }) async {
    return _safeCall(() async {
      // ⛔ Cooldown check
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

        // ✅ SUCCESS
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

        // ⚠️ RATE LIMIT
        if (response.statusCode == 429) {
          _cooldownUntil =
              DateTime.now().add(const Duration(seconds: 30));
          throw Exception('Rate limited. Please wait ~30 seconds.');
        }

        // ❌ Other errors
        throw Exception(
            'Groq API error ${response.statusCode}: ${response.body}');
      } on TimeoutException {
        throw Exception('Request timed out. Try again.');
      } catch (e) {
        final msg = e.toString();

        if (msg.contains('SocketException')) {
          throw Exception('Network error. Check connection.');
        }

        rethrow;
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  // 🧠 JSON CLEANER (unchanged)
  // ─────────────────────────────────────────────────────────
  static String _extractJson(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final objMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    return objMatch?.group(0) ?? cleaned;
  }

  // ─────────────────────────────────────────────────────────
  // 📄 RESUME ANALYSIS (unchanged logic)
  // ─────────────────────────────────────────────────────────
  static Future<Map<String, String>> analyzeResume({
    required String resumeText,
    required String codingProfileData,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Missing GROQ_API_KEY in .env');
    }

    _emit('Preparing resume analysis...');

    // Groq has much higher context — use more of the resume for better analysis
    final trimmedResume =
        resumeText.length > 3000 ? resumeText.substring(0, 3000) : resumeText;

    final trimmedStats = codingProfileData.length > 600
        ? codingProfileData.substring(0, 600)
        : codingProfileData;

    final prompt = '''
You are a senior technical recruiter at a top tech company (Google/Amazon/Microsoft level).
Carefully read the FULL resume text below and perform a detailed analysis.

RESUME TEXT:
$trimmedResume

CANDIDATE CODING STATS:
$trimmedStats

Your task — return ONLY a raw JSON object (no markdown, no code fences, no explanation):

ATS SCORE RULES (be accurate, not generous):
- Start at 75 as baseline for any structured tech resume
- Add 1-5 points for: quantified achievements (numbers/%), strong action verbs, relevant keywords (algorithms, data structures, system design, cloud), GitHub/LeetCode links present
- Add 1-5 points for: clear sections (Education, Experience, Projects, Skills), clean formatting, no spelling errors visible
- Subtract 5-15 points for: missing quantification, vague descriptions ("worked on", "helped with"), no links, missing skills section, generic objective statement
- Typical good tech resume: 72-88. Only give 90+ for truly exceptional resumes.

RECOMMENDATIONS RULES (this is the most important part):
- Each recommendation MUST reference something SPECIFIC from this resume (quote a job title, project name, skill, or exact phrase you see in the resume text)
- Do NOT give generic advice like "add more metrics" — instead say "The '${resumeText.split('\n').firstWhere((l) => l.length > 5, orElse: () => 'your experience')}' entry lacks measurable impact — add numbers like team size, user count, or % improvement"
- Focus on what is MISSING or WEAK in THIS specific resume, not general tips
- Give 4 concrete, actionable recommendations

Return this exact JSON structure:
{
  "ats_score": <integer between 60 and 95>,
  "resume_summary": [
    "<specific strength from resume — name what makes it strong>",
    "<specific skill or experience that stands out>",
    "<specific achievement or project worth highlighting>"
  ],
  "coding_summary": [
    "<insight about their coding stats relative to their experience level>",
    "<specific observation about their strongest platform or skill>"
  ],
  "recommendations": [
    "<specific improvement referencing actual resume content — e.g. 'Your [project/role] description says X, add Y to make it stronger'>",
    "<specific missing element — e.g. 'No GitHub/portfolio link found — add it to the header'>",
    "<specific keyword gap — e.g. 'Skills section missing [technology seen in job descriptions for your role]'>",
    "<specific formatting or content fix — e.g. 'The [section] has no quantified results — add numbers'>"
  ]
}''';



    try {
      final raw = await _callGemini(prompt, maxOutputTokens: 1500);
      final cleaned = _extractJson(raw);
      final result = jsonDecode(cleaned) as Map<String, dynamic>;

      if (result['ats_score'] == null || result['resume_summary'] == null) {
        throw Exception('Incomplete analysis. Please try again.');
      }

      String formatList(dynamic field) {
        if (field is List) {
          return field
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .map((e) => '• $e')
              .join('\n');
        }
        return field.toString().trim();
      }

      // Clamp ATS score to realistic range
      final rawScore = (result['ats_score'] as num?)?.toInt() ?? 75;
      final atsScore = rawScore.clamp(60, 95);

      return {
        'ats_score': atsScore.toString(),
        'resume_summary': formatList(result['resume_summary'] ?? []),
        'coding_summary': formatList(result['coding_summary'] ?? []),
        'recommendations': formatList(result['recommendations'] ?? []),
      };
    } catch (e) {
      debugPrint('[AIService] analyzeResume error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }


  // ─────────────────────────────────────────────────────────
  // ⚡ INSIGHTS (unchanged logic)
  // ─────────────────────────────────────────────────────────
  static Future<List<String>> generateInsights({
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prompt = '''
Give exactly 2 short coding insights.
Return ONLY JSON array.

Stats: ${jsonEncode(userData)}
''';

      final raw = await _callGemini(prompt, maxOutputTokens: 200);
      final cleaned = _extractJson(raw);

      final decoded = jsonDecode(cleaned);

      if (decoded is List) {
        return decoded.map((e) => e.toString()).take(2).toList();
      }

      throw Exception('Invalid format');
    } catch (e) {
      debugPrint('[AIService] fallback insights: $e');
      return [
        '📈 Keep solving consistently.',
        '🚀 Try harder problems gradually.',
      ];
    }
  }
}