import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const _model = 'gemini-2.5-flash';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  // ──────────────────────────────────────────────────────────────────────────
  // Core REST caller
  // ──────────────────────────────────────────────────────────────────────────

  static Future<String> _callGemini(
    String prompt, {
    int maxOutputTokens = 1024,
  }) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1, // Near-deterministic for consistent scoring and analysis
        'maxOutputTokens': maxOutputTokens,
        'responseMimeType': 'application/json', // Forces JSON mode for speed and reliability
      },
    });

    debugPrint('[AIService] POST $_baseUrl (maxTokens: $maxOutputTokens)');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      debugPrint('[AIService] HTTP ${response.statusCode}: ${response.body}');
      throw Exception(
          'Gemini API returned HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates.');
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned empty text.');
    }

    return text.trim();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Robust JSON extractor — strips markdown fences and finds first JSON block
  // ──────────────────────────────────────────────────────────────────────────

  static String _extractJson(String raw) {
    // Strip markdown code fences
    var cleaned = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Try to extract a JSON object {...}
    final objMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (objMatch != null) return objMatch.group(0)!.trim();

    // Try to extract a JSON array [...]
    final arrMatch = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
    if (arrMatch != null) return arrMatch.group(0)!.trim();

    return cleaned;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Resume Analyzer
  // ──────────────────────────────────────────────────────────────────────────

  static Future<Map<String, String>> analyzeResume({
    required String resumeText,
    required String codingProfileData,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is not configured. Please add GEMINI_API_KEY to your .env file.',
      );
    }

    // Keep input short so there is enough token budget for the JSON output
    final trimmedResume =
        resumeText.length > 6000 ? resumeText.substring(0, 6000) : resumeText;

    final prompt = '''
You are an expert technical recruiter and resume analyst. Your task is to provide a consistent and objective ATS (Applicant Tracking System) score and analysis.

DATA 1 – Resume Text:
$trimmedResume

DATA 2 – Coding Profile Summary:
$codingProfileData

TASK:
Return ONLY a valid JSON object with exactly these four keys:
{
  "ats_score": <Integer (0-100). Follow the strict rubric below.>, 
  "resume_summary": ["Point 1", "Point 2", ...], 
  "coding_summary": ["Point 1", "Point 2", ...],
  "recommendations": ["Point 1", "Point 2", ...]
}

SCORING RUBRIC (Strictly follow this for "ats_score"):
- Start with a Base Score of 100.
- Deduct 10 points if no quantifiable metrics (e.g., %, \$, "reduced latency by Xms") are found in work experience.
- Deduct 10 points if the resume is mostly generic phrases (e.g., "Team player", "Hard worker") without proof.
- Deduct 10 points for missing or weak "Skills" section (languages, frameworks, tools).
- Deduct 5 points for lack of links (GitHub, Portfolio, LinkedIn).
- Deduct 10 points if the coding profile data (Data 2) shows low activity or no significant achievements.
- Deduct 5 points for poor structural flow or dense blocks of text.

Rules:
- BE STRICT and OBJECTIVE. Analyzing the same data must yield the same score.
- "resume_summary": 4-6 high-impact points highlighting skills and experience.
- "recommendations": 3-4 specific, actionable improvements.
- Use professional, active language. NO markdown.
- Pure JSON only.
''';

    debugPrint('[AIService] Sending resume analysis request...');

    try {
      // Use 8192 tokens so the full JSON response is never truncated
      final rawText = await _callGemini(prompt, maxOutputTokens: 8192);
      debugPrint('[AIService] Raw AI response: $rawText');

      final cleaned = _extractJson(rawText);
      final result = jsonDecode(cleaned) as Map<String, dynamic>;

      final atsScore = result['ats_score']?.toString() ?? 'N/A';

      String formatAIField(dynamic field) {
        if (field == null) return '';
        List<String> items = [];
        
        if (field is List) {
          items = field.map((e) => e.toString().trim()).toList();
        } else {
          // Fallback: split by common delimiters if AI returns a string
          items = field.toString().split(RegExp(r'[\n•\-\*]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        // Prefix each with a clean bullet and join
        return items.map((item) => '- $item').join('\n');
      }

      final resumeSummary = formatAIField(result['resume_summary']);
      final codingSummary = formatAIField(result['coding_summary']);
      final recommendations = formatAIField(result['recommendations']);

      if (resumeSummary.isEmpty || codingSummary.isEmpty) {
        throw Exception('AI returned empty summaries.');
      }

      debugPrint('[AIService] Resume analysis complete. ATS Score: $atsScore');

      return {
        'ats_score': atsScore,
        'resume_summary': resumeSummary,
        'coding_summary': codingSummary,
        'recommendations': recommendations,
      };
    } catch (e) {
      debugPrint('[AIService] analyzeResume error: $e');
      throw Exception('Gemini API error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // AI Coding Insights
  // ──────────────────────────────────────────────────────────────────────────

  static Future<List<String>> generateInsights({
    required Map<String, dynamic> userData,
  }) async {
    if (_apiKey.isEmpty) {
      debugPrint('[AIService] No API key, using fallback insights.');
      return _buildFallbackInsights(userData);
    }

    final prompt = '''
You are a senior coding mentor and performance analyst. 
Analyze the user's coding statistics and generate exactly 2–3 short, data-driven, and actionable bullet-point insights.

Categories to address (Pick 2–3):
1. Solving Pattern: Analyze recent volume vs difficulty (Easy/Med/Hard).
2. Consistency: Analyze streak, activity gaps, and GitHub commits.
3. Growth Recommendation: Suggest specific next topic or difficulty based on strengths/weaknesses.

User Data (JSON):
${jsonEncode(userData)}

Rules:
- Output only 2–3 concise points.
- Each point MUST reference a specific number from the data (e.g. "8 Medium solved").
- Keep points under 18 words and include a relevant emoji.
- Return ONLY a JSON list of strings [""]. No markdown. No backticks.
''';

    debugPrint('[AIService] Generating Smart Insights via Gemini...');

    try {
      final rawText = await _callGemini(prompt);

      final cleaned = _extractJson(rawText);
      final List<dynamic> result = jsonDecode(cleaned);
      final List<String> insights = result.map((e) => e.toString()).toList();

      if (insights.isEmpty) throw Exception('Empty insights list returned.');

      debugPrint('[AIService] Insights generated: ${insights.length}');
      return insights.take(3).toList();
    } catch (e) {
      debugPrint('[AIService] Insights API error: $e — using fallback.');
      return _buildFallbackInsights(userData);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Rule-Based Fallback (mirrors AI style with real data)
  // ──────────────────────────────────────────────────────────────────────────

  static List<String> _buildFallbackInsights(Map<String, dynamic> data) {
    final insights = <String>[];

    final solved = (data['totalSolved'] as num?)?.toInt() ?? 0;
    final weekly = (data['weeklySolved'] as num?)?.toInt() ?? 0;
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final github = (data['githubCommits'] as num?)?.toInt() ?? 0;

    final topics = data['topics'] as Map<String, dynamic>? ?? {};
    final weakTopics = (topics['weak'] as List?)?.cast<String>() ?? [];

    final diff = data['difficulty'] as Map<String, dynamic>? ?? {};
    final hard = (diff['hard'] as num?)?.toInt() ?? 0;
    final med = (diff['medium'] as num?)?.toInt() ?? 0;

    // 1. Solving Pattern Analysis
    if (weekly > 10) {
      insights.add(
          'High momentum! You solved $weekly problems this week. Aim for ${weekly + 3} next cycle! 📈');
    } else if (solved > 0) {
      insights.add(
          'You have solved $solved problems total — consistency is your next big challenge. 🛠️');
    } else {
      insights.add(
          'Start your journey today! Solve 1 Easy problem to initialize your stats. 🚀');
    }

    // 2. Consistency Analysis
    if (streak > 0) {
      insights.add(
          'Solid $streak-day streak! Keep solving to hit the ${streak + 5} day milestone. 🔥');
    } else if (github > 0) {
      insights.add(
          'Great balance: Your $github GitHub commits show project building maturity. 💻');
    } else {
      insights.add(
          'No activity yet. Try solving 3 problems this week to build consistency. 📅');
    }

    // 3. Smart Suggestions
    if (weakTopics.isNotEmpty) {
      insights.add(
          'Strategic focus: Target ${weakTopics.first} problems as it is your primary weakness. 🎯');
    } else if (hard < 2) {
      insights.add(
          'Level up: You have $hard Hard solved. Solving 2 more will boost your rating. 🏆');
    } else if (med > 10) {
      insights.add(
          'Confidence check: With $med Mediums, start attacking Hard problems to reach Top 1%. 💎');
    }

    return insights.take(3).toList();
  }
}