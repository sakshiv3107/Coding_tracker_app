import 'dart:convert';
import 'package:http/http.dart' as http;

class ProxyService {
  static Future<Map<String, dynamic>?> getDailyChallenge() async {
    const url = "https://leetcode.com/graphql";
    const query = r"""
      query questionOfToday {
        activeDailyCodingChallengeQuestion {
          date
          userStatus
          link
          question {
            acRate
            difficulty
            freqBar
            questionId
            frontendQuestionId: questionFrontendId
            isFavor
            paidOnly: isPaidOnly
            status
            title
            titleSlug
            hasVideoSolution
            hasSolution
            topicTags {
              name
              id
              slug
            }
          }
        }
      }
    """;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "query": query,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['activeDailyCodingChallengeQuestion'];
      }
    } catch (e) {
      print("Error fetching daily challenge: $e");
    }
    return null;
  }
}
