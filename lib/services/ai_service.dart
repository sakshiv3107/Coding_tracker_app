import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<Map<String, String>> analyzeResume({
    required String resumeText,
    required String codingProfileData,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Gemini API key not found in .env');
    }

    final prompt = """
You are an expert technical recruiter and resume analyst.
I will provide you with two pieces of data:
1. Text extracted from a candidate's resume.
2. A summary of their coding profiles (LeetCode, HackerRank, etc.).

Data 1 (Resume Text):
$resumeText

Data 2 (Coding Profile):
$codingProfileData

TASK:
Generate two separate professional summaries in JSON format:
{
  "resume_summary": "A professional cumulative summary (4-6 lines) based ONLY on the resume text, covering skills, projects, experience, and achievements.",
  "coding_summary": "A performance-based summary (2-4 lines) based ONLY on the coding profile data, highlighting problem-solving consistency, platform counts, and rankings."
}

JSON ONLY. NO CHATTY TEXT. NO MARKDOWN BACKTICKS.
""";

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'responseMimeType': 'application/json', // Forces JSON-only output
          },
          'systemInstruction': {
            'parts': [
              {'text': 'You are a technical recruiter assistant. Always respond with valid JSON only.'}
            ]
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Gemini response path: candidates[0].content.parts[0].text
        final content = data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Strip markdown code fences if present (safety net)
        final cleaned = content
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();

        final Map<String, dynamic> result = jsonDecode(cleaned);
        return {
          'resume_summary': result['resume_summary']?.toString() ??
              'Failed to generate resume summary.',
          'coding_summary': result['coding_summary']?.toString() ??
              'Failed to generate coding summary.',
        };
      } else {
        throw Exception('AI analysis failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('AI Service Error: $e');
    }
  }

}