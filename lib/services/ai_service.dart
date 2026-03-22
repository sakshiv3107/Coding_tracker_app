import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  static Future<Map<String, String>> analyzeResume({
    required String resumeText,
    required String codingProfileData,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('OpenAI API key not found in .env');
    }

    final prompt = """
    You are an expert technical recruiter and resume analyst.
    I will provide you with two pieces of data:
    1. Text extracted from a candidate's resume.
    2. A summary of their coding profiles (LeetCode, HackerRank, etc.).

    Data 1 (Resume Text):
    \$resumeText

    Data 2 (Coding Profile):
    \$codingProfileData

    TASK:
    Generate two separate professional summaries in JSON format:
    {
      "resume_summary": "A professional cumulative summary (4-6 lines) based ONLY on the resume text, covering skills, projects, experience, and achievements.",
      "coding_summary": "A performance-based summary (2-4 lines) based ONLY on the coding profile data, highlighting problem-solving consistency, platform counts, and rankings."
    }

    JSON ONLY. NO CHATTY TEXT.
    """;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': 'You are a technical recruiter assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final Map<String, dynamic> result = jsonDecode(content);
        return {
          'resume_summary': result['resume_summary']?.toString() ?? 'Failed to generate resume summary.',
          'coding_summary': result['coding_summary']?.toString() ?? 'Failed to generate coding summary.',
        };
      } else {
        throw Exception('AI analysis failed: \${response.body}');
      }
    } catch (e) {
      throw Exception('AI Service Error: \$e');
    }
  }

  // Fallback / Dummy analysis for testing or if API key is missing
  static Future<Map<String, String>> getDummyAnalysis() async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      "resume_summary": "Strong technical background with expertise in Flutter and modern backend architectures. Developed scalable mobile applications and integrated complex APIs, consistently delivering high-quality code. Recognized for leadership in managing full-cycle software development projects and achieving significant performance optimizations.",
      "coding_summary": "Extremely active problem solver with a deep focus on Data Structures and Algorithms. Solved hundreds of problems across platforms like LeetCode and HackerRank, maintaining a high contest rating and proving consistent dedication to competitive programming."
    };
  }
}
