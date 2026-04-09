// lib/services/ai_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static DateTime? _cooldownUntil;

  static final _statusController = StreamController<String>.broadcast();
  static Stream<String> get statusStream => _statusController.stream;

  static void _emit(String msg) {
    debugPrint('[AIService] $msg');
    if (!_statusController.isClosed) _statusController.add(msg);
  }

  // ---------------------------------------------------------------------------
  // Queue / rate-limit guard
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Core Groq caller
  // ---------------------------------------------------------------------------
  static Future<String> _callGroq(
    String prompt, {
    int maxTokens = 1024,
    double temperature = 0.2,
  }) async {
    return _safeCall(() async {
      if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
        final secs = _cooldownUntil!.difference(DateTime.now()).inSeconds + 1;
        throw Exception('Rate limited. Please wait ~$secs seconds.');
      }

      _emit('Calling Groq AI...');

      try {
        final response = await http
            .post(
              Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
              },
              body: jsonEncode({
                'model': 'llama-3.1-8b-instant',
                'messages': [
                  {'role': 'user', 'content': prompt}
                ],
                'temperature': temperature,
                'max_tokens': maxTokens,
              }),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text =
              data['choices'][0]['message']['content'] as String? ?? '';
          if (text.trim().isEmpty) throw Exception('Empty response from Groq.');
          _cooldownUntil = null;
          _emit('Done.');
          return text.trim();
        }

        if (response.statusCode == 429) {
          _cooldownUntil = DateTime.now().add(const Duration(seconds: 30));
          throw Exception('Rate limited. Please wait ~30 seconds.');
        }

        throw Exception(
            'Groq API error ${response.statusCode}: ${response.body}');
      } on TimeoutException {
        throw Exception('Request timed out. Please try again.');
      } catch (e) {
        rethrow;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // JSON extractor — robust against markdown fences & surrounding text
  // ---------------------------------------------------------------------------
  static String _extractJson(String raw) {
    String cleaned = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final firstRect = cleaned.indexOf('[');
    final lastRect = cleaned.lastIndexOf(']');
    final firstCurly = cleaned.indexOf('{');
    final lastCurly = cleaned.lastIndexOf('}');

    if (firstRect != -1 &&
        lastRect != -1 &&
        (firstCurly == -1 || firstRect < firstCurly)) {
      if (lastRect > firstRect) return cleaned.substring(firstRect, lastRect + 1);
    } else if (firstCurly != -1 && lastCurly != -1) {
      if (lastCurly > firstCurly) return cleaned.substring(firstCurly, lastCurly + 1);
    }

    return cleaned;
  }

  // ---------------------------------------------------------------------------
  // RESUME ANALYZER  (main feature)
  // ---------------------------------------------------------------------------

  /// Analyzes a resume against a 6-criterion ATS rubric.
  ///
  /// Returns a [ResumeAnalysisResult] containing:
  ///   - [atsScore]       : int, realistically calibrated 60-95
  ///   - [scoreCriteria]  : per-criterion breakdown
  ///   - [resumeSummary]  : key-point bullets about the candidate
  ///   - [recommendations]: specific, actionable improvement tips
  static Future<ResumeAnalysisResult> analyzeResume({
    required String resumeText,
    String? jobDescription,
  }) async {
    if (_apiKey.isEmpty) throw Exception('Missing GROQ_API_KEY in .env');

    _emit('Preparing ATS analysis...');

    // Trim to avoid token overflow while keeping meaningful content
    final trimmed =
        resumeText.length > 4000 ? resumeText.substring(0, 4000) : resumeText;

    final jdSection = (jobDescription != null && jobDescription.trim().isNotEmpty)
        ? 'JOB DESCRIPTION (optional context):\n${jobDescription.substring(0, jobDescription.length.clamp(0, 800))}'
        : 'JOB DESCRIPTION: Not provided. Evaluate as a general technical resume.';

    // -----------------------------------------------------------------------
    // Prompt — strict rubric forces balanced, realistic scoring (avg 70-85)
    // -----------------------------------------------------------------------
    final prompt = '''
You are an expert ATS (Applicant Tracking System) evaluator with 10+ years of experience in technical recruiting.

Evaluate the following resume using the STRICT ATS rubric below. Be BALANCED — not too lenient, not too harsh.
Scoring guidelines:
  - A score of 90+ is RARE and reserved for near-perfect resumes.
  - A score of 60-70 indicates clear, fixable issues.
  - Most decent resumes should land between 70-85.
  - Never give 100. Never give below 40 unless the text is clearly not a resume.

=== ATS RUBRIC (6 criteria, total 100 points) ===

1. FORMAT & TEMPLATE COMPATIBILITY (20 pts)
   - Uses clean, single-column or simple two-column layout (no tables, text boxes, or graphics)
   - Standard section headings: Summary, Experience, Education, Skills, Projects
   - Consistent font usage, clear section separation
   - File should be ATS-parsable (no images replacing text)
   Deduct: heavy tables (-8), missing standard sections (-4 each), graphics/logos in header (-5)

2. ACTION VERBS & LANGUAGE STRENGTH (20 pts)
   - Bullet points begin with strong action verbs (e.g., "Developed", "Architected", "Reduced", "Led", "Implemented")
   - Avoid weak openers: "Responsible for", "Helped with", "Worked on", "Assisted in"
   - Avoid first-person pronouns (I, me, my)
   - Active voice throughout
   Deduct: each weak opener (-1.5), first-person use (-2), passive voice (-1 per instance, max -5)

3. QUANTIFIABLE ACHIEVEMENTS (20 pts)
   - Bullets include measurable outcomes: percentages, numbers, time saved, scale, team size
   - At least 40% of experience bullets should contain a metric
   Deduct: fewer than 2 metrics (-8), fewer than 5 metrics (-4), vague impact language (-2 per instance)

4. KEYWORD & SKILLS RELEVANCE (20 pts)
   - Technical skills explicitly listed in a Skills section
   - Tools, frameworks, languages are named (not just implied)
   - If JD provided: penalize missing critical keywords
   Deduct: no dedicated Skills section (-6), skills only mentioned in prose (-3), missing keyword density (-4)

5. CONTACT & PROFESSIONAL LINKS (10 pts)
   - Full name, professional email, phone, LinkedIn URL, GitHub/portfolio (for tech roles)
   Deduct: missing LinkedIn (-3), missing GitHub/portfolio for tech role (-3), non-professional email (-2)

6. COMPLETENESS & CONSISTENCY (10 pts)
   - Dates are consistent (MM/YYYY or YYYY format, no gaps without explanation)
   - Job titles and company names are present
   - Education section has degree, institution, graduation year
   Deduct: unexplained date gaps (-3), missing graduation year (-2), inconsistent date format (-2)

=== END RUBRIC ===

RESUME TEXT:
$trimmed

$jdSection

=== OUTPUT INSTRUCTIONS ===
Return ONLY a raw JSON object — no markdown, no explanation, no preamble.

{
  "ats_score": <int between 40 and 95>,
  "score_breakdown": {
    "format_template": { "score": <int 0-20>, "note": "<one sentence>" },
    "action_verbs": { "score": <int 0-20>, "note": "<one sentence>" },
    "quantifiable_achievements": { "score": <int 0-20>, "note": "<one sentence>" },
    "keyword_relevance": { "score": <int 0-20>, "note": "<one sentence>" },
    "contact_links": { "score": <int 0-10>, "note": "<one sentence>" },
    "completeness": { "score": <int 0-10>, "note": "<one sentence>" }
  },
  "resume_summary": [
    "<Key point 1 about candidate background>",
    "<Key point 2 about skills or experience>",
    "<Key point 3 about education or projects>",
    "<Key point 4 about notable achievements or gaps>"
  ],
  "recommendations": [
    {
      "priority": "high",
      "category": "<Format|Action Verbs|Metrics|Keywords|Contact|Completeness>",
      "issue": "<Specific problem found in the resume>",
      "fix": "<Exact, actionable fix with example if possible>"
    }
  ]
}

IMPORTANT RULES for recommendations:
- Provide 5 to 7 recommendations total.
- "high" priority = must fix before applying; "medium" = important improvement; "low" = polish.
- The "fix" field must be SPECIFIC and PRACTICAL. 
  BAD: "Add more metrics."
  GOOD: "In your internship at XYZ bullet 2, replace 'improved performance' with 'improved API response time by 40% using Redis caching'."
- Do NOT repeat the same category more than twice.
- Order recommendations by priority: high first, then medium, then low.
''';

    try {
      _emit('Running ATS evaluation...');
      final raw = await _callGroq(prompt, maxTokens: 2000, temperature: 0.15);
      final cleaned = _extractJson(raw);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;

      _emit('Parsing results...');
      return ResumeAnalysisResult.fromJson(json);
    } catch (e) {
      debugPrint('[AIService] analyzeResume error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ---------------------------------------------------------------------------
  // OTHER FEATURES (unchanged, cleaned up)
  // ---------------------------------------------------------------------------

  static Future<List<String>> generateInsights({
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prompt =
          'Give 2 short, practical coding improvement insights for this developer profile: '
          '${jsonEncode(userData)}. Return ONLY a raw JSON array of strings. No markdown.';
      final raw = await _callGroq(prompt, maxTokens: 250);
      final decoded = jsonDecode(_extractJson(raw));
      if (decoded is List) {
        return decoded.map((e) => e.toString()).take(2).toList();
      }
      return ['Keep your practice consistent to build momentum.'];
    } catch (_) {
      return [
        'Keep your practice consistent to build momentum.',
        'Push yourself to attempt harder difficulty problems weekly.'
      ];
    }
  }

  static Future<List<dynamic>> generateStructuredInsights({
    required Map<String, dynamic> userData,
  }) async {
    final prompt = '''
Analyze these coding statistics and return EXACTLY 3 personalized insights.
Return ONLY a raw JSON array. NO markdown, NO preamble.

Structure:
[
  {
    "id": "unique_string_id",
    "title": "Short descriptive title",
    "reason": "Why this insight matters for this user",
    "impact": "Concrete next action to take",
    "confidence": "High or Medium",
    "topic": "Primary DSA/CS topic",
    "type": "weakness or strength or slowness or errorRate"
  }
]

User Data: ${jsonEncode(userData)}
''';
    try {
      final raw = await _callGroq(prompt, maxTokens: 900);
      return jsonDecode(_extractJson(raw)) as List<dynamic>;
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
Generate a focused 3-step action plan to improve at "$topic" based on the identified weakness: "$insightTitle".
Return ONLY a raw JSON object. No markdown.

{
  "steps": ["Step 1 with details", "Step 2 with details", "Step 3 with details"],
  "resources": [{"title": "Resource name", "url": "https://..."}],
  "estimatedTime": "X weeks"
}
''';
    try {
      final raw = await _callGroq(prompt, maxTokens: 600);
      return jsonDecode(_extractJson(raw));
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
Generate 3 personalized coding practice recommendations based on this developer performance.
Return ONLY a raw JSON array. No markdown.

[
  {
    "id": "rec_unique_id",
    "title": "Actionable recommendation title",
    "description": "One or two sentence explanation",
    "type": "focus or improve or challenge or balance",
    "topic": "Specific topic name",
    "priority": <1, 2, or 3>
  }
]

Context:
- Total problems solved: $totalSolved
- Difficulty breakdown: ${jsonEncode(difficultyBreakdown)}
- Key insights: ${jsonEncode(insights)}
- Recent submissions (last 10): ${jsonEncode(recentSubmissions.take(10).toList())}
''';
    try {
      final raw = await _callGroq(prompt, maxTokens: 700);
      return jsonDecode(_extractJson(raw)) as List<dynamic>;
    } catch (e) {
      debugPrint('[AIService] generateRecommendations error: $e');
      rethrow;
    }
  }

  static Future<List<String>> classifyProblem(String title) async {
    final prompt =
        'Classify the LeetCode/DSA problem titled "$title" into 1-3 algorithm/data-structure topics. '
        'Return ONLY a raw JSON array of short topic strings. No markdown.';
    try {
      final raw = await _callGroq(prompt, maxTokens: 80);
      final decoded = jsonDecode(_extractJson(raw));
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
      return ['General'];
    } catch (_) {
      return ['General'];
    }
  }
}

// =============================================================================
// DATA MODELS for Resume Analysis
// =============================================================================

class ResumeAnalysisResult {
  final int atsScore;
  final Map<String, CriterionScore> scoreBreakdown;
  final List<String> resumeSummary;
  final List<ResumeRecommendation> recommendations;

  const ResumeAnalysisResult({
    required this.atsScore,
    required this.scoreBreakdown,
    required this.resumeSummary,
    required this.recommendations,
  });

  factory ResumeAnalysisResult.fromJson(Map<String, dynamic> json) {
    // --- ATS Score ---
    final rawScore = (json['ats_score'] as num?)?.toInt() ?? 72;
    final clampedScore = rawScore.clamp(40, 95);

    // --- Score Breakdown ---
    final breakdownRaw =
        json['score_breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = <String, CriterionScore>{};
    breakdownRaw.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        breakdown[key] = CriterionScore.fromJson(value);
      }
    });

    // --- Resume Summary ---
    final summaryRaw = json['resume_summary'];
    final summary = summaryRaw is List
        ? summaryRaw.map((e) => e.toString()).toList()
        : <String>[];

    // --- Recommendations ---
    final recsRaw = json['recommendations'];
    final recs = recsRaw is List
        ? recsRaw
            .whereType<Map<String, dynamic>>()
            .map(ResumeRecommendation.fromJson)
            .toList()
        : <ResumeRecommendation>[];

    return ResumeAnalysisResult(
      atsScore: clampedScore,
      scoreBreakdown: breakdown,
      resumeSummary: summary,
      recommendations: recs,
    );
  }

  /// Convenience: score as a 0.0–1.0 percentage
  double get atsScorePercent => atsScore / 100.0;

  /// High-priority recommendations only
  List<ResumeRecommendation> get highPriorityRecs =>
      recommendations.where((r) => r.priority == 'high').toList();

  /// Label for the ATS score
  String get scoreLabel {
    if (atsScore >= 88) return 'Excellent';
    if (atsScore >= 78) return 'Good';
    if (atsScore >= 68) return 'Fair';
    return 'Needs Work';
  }
}

class CriterionScore {
  final int score;
  final String note;

  const CriterionScore({required this.score, required this.note});

  factory CriterionScore.fromJson(Map<String, dynamic> json) {
    return CriterionScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      note: json['note']?.toString() ?? '',
    );
  }
}

class ResumeRecommendation {
  final String priority; // "high" | "medium" | "low"
  final String category;
  final String issue;
  final String fix;

  const ResumeRecommendation({
    required this.priority,
    required this.category,
    required this.issue,
    required this.fix,
  });

  factory ResumeRecommendation.fromJson(Map<String, dynamic> json) {
    return ResumeRecommendation(
      priority: json['priority']?.toString() ?? 'medium',
      category: json['category']?.toString() ?? 'General',
      issue: json['issue']?.toString() ?? '',
      fix: json['fix']?.toString() ?? '',
    );
  }

  bool get isHigh => priority == 'high';
  bool get isMedium => priority == 'medium';
}
