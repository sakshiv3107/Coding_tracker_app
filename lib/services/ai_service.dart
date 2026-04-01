import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

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

    final trimmedResume =
        resumeText.length > 8000 ? resumeText.substring(0, 8000) : resumeText;

    final prompt = '''
You are an expert technical recruiter and resume analyst.

DATA 1 – Resume Text:
$trimmedResume

DATA 2 – Coding Profile Summary:
$codingProfileData

TASK:
Return ONLY a valid JSON object with exactly these four keys:
{
  "ats_score": <Integer from 1 to 100>,
  "resume_summary": "A list of 4-6 concise bullet points (Skills, Experience, Highlights)",
  "coding_summary": "A list of 2-4 concise bullet points (Rankings, Consistency)",
  "recommendations": "A list of 3-4 actionable, high-impact bullet points for resume improvement (e.g., adding missing skills, re-formatting, or quantifying achievements)."
}

Rules:
- USE simple bullet points with '-' or '•'.
- NO markdown formatting (no bold/italics in the strings).
- NO backticks around the JSON.
- Valid JSON format only.
''';

    debugPrint('[AIService] Sending resume analysis request via Google Generative AI...');

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
      
      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text ?? '';
      
      debugPrint('[AIService] Raw AI response: $rawText');

      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final result = jsonDecode(cleaned) as Map<String, dynamic>;

      final atsScore = result['ats_score']?.toString() ?? 'N/A';

      String formatAIField(dynamic field) {
        if (field == null) return '';
        if (field is List) {
          return field.map((e) => e.toString().trim()).join('\n');
        }
        return field.toString().trim();
      }

      final resumeSummary = formatAIField(result['resume_summary']);
      final codingSummary = formatAIField(result['coding_summary']);
      final recommendations = formatAIField(result['recommendations']);

      if (resumeSummary.isEmpty || codingSummary.isEmpty) {
        throw Exception('AI returned empty summaries.');
      }

      return {
        'ats_score': atsScore,
        'resume_summary': resumeSummary,
        'coding_summary': codingSummary,
        'recommendations': recommendations,
      };
    } catch (e) {
      debugPrint('[AIService] Exception: $e');
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
You are a career coach and competitive programming expert. 
Analyze the user's coding statistics and generate 3-4 short, personalized, data-driven insights.

User Statistics:
${jsonEncode(userData)}

Rules:
1. Base every insight on the actual numbers provided — reference specific values (e.g., "717 problems solved").
2. Compare current activity vs goals if goal data is present.
3. Identify strengths or gaps in topics/difficulty distribution.
4. Highlight consistency, streaks, or inactivity patterns.
5. Each insight must be under 18 words and include a relevant emoji.
6. Return a JSON array of strings. No extra text. No markdown.

Example format: ["Insight 1 🔥", "Insight 2 💻", "Insight 3 📈"]
''';

    debugPrint('[AIService] Sending insights request via Google Generative AI...');

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final rawText = response.text ?? '';
      
      debugPrint('[AIService] Raw insights: $rawText');

      final cleaned = rawText
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final List<dynamic> result = jsonDecode(cleaned);
      final insights = result.map((e) => e.toString()).toList();

      if (insights.isEmpty) throw Exception('Empty insights list');
      return insights;
    } catch (e) {
      debugPrint('[AIService] Insights error: $e');
      return _buildFallbackInsights(userData);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Data-driven fallback (uses real numbers — never shows generic messages)
  // ──────────────────────────────────────────────────────────────────────────

  static List<String> _buildFallbackInsights(Map<String, dynamic> data) {
    final List<String> insights = [];

    final totalSolved = (data['totalSolved'] as num?)?.toInt() ?? 0;
    final solvedToday = (data['solvedToday'] as num?)?.toInt() ?? 0;
    final weeklySolved = (data['weeklySolved'] as num?)?.toInt() ?? 0;
    final leetcodeSolved = (data['leetcodeSolved'] as num?)?.toInt() ?? 0;
    final codeforcesSolved = (data['codeforcesSolved'] as num?)?.toInt() ?? 0;
    final githubCommits = (data['githubCommits'] as num?)?.toInt() ?? 0;
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final devScore = (data['developerScore'] as num?)?.toInt() ?? 0;
    final devLevel = data['developerLevel']?.toString() ?? 'Beginner';

    // 1. Consistency / Streak
    if (solvedToday == 0) {
      insights.add('No problems solved today yet. A quick Easy solve will keep the engine running! 🎯');
    } else {
      insights.add('Great job! You solved $solvedToday problem${solvedToday > 1 ? "s" : ""} today. Keep it up! 🔥');
    }

    if (streak > 5) {
      insights.add('Impressive $streak-day streak! Your consistency is putting you in the top 5% of learners. 🔥');
    } else if (streak > 0) {
      insights.add('$streak-day streak! Don\'t let it break — solve one more today. 💪');
    }

    // 2. Weekly Momentum
    if (weeklySolved > 10) {
      insights.add('Power week! $weeklySolved problems solved in the last 7 days. You\'re on fire. 🚀');
    } else if (weeklySolved > 0) {
      insights.add('Steadily growing: $weeklySolved solutions this week. Aim for ${weeklySolved + 2} by Sunday! 📈');
    }

    // 3. Platform mix / Total
    if (totalSolved > 500) {
      insights.add('Over 500 problems solved! You have the foundations of a Senior Engineer. 🏆');
    } else if (leetcodeSolved > 0 && codeforcesSolved > 0) {
      insights.add('Awesome platform spread between LeetCode and Codeforces. Versatility is key. 🌐');
    }

    // GitHub insight
    if (githubCommits > 0) {
      insights.add('$githubCommits GitHub contributions — keep building! 💻');
    } else {
      insights.add('Push a project to GitHub to showcase your $devLevel skills publicly. 📂');
    }

    // Developer score
    if (devScore > 0) {
      insights.add('Developer Score: $devScore — Level: $devLevel. Keep climbing! ⭐');
    }

    // Goal insights
    final goalData = data['goalProgress'];
    if (goalData is List && goalData.isNotEmpty) {
      final incomplete = goalData.where((g) => g['isCompleted'] == false).toList();
      if (incomplete.isNotEmpty) {
        insights.add('${incomplete.length} goal${incomplete.length > 1 ? "s" : ""} in progress — stay focused! 🎯');
      } else {
        insights.add('All goals completed! Set a harder challenge. 🏅');
      }
    }

    return insights.take(4).toList();
  }
}