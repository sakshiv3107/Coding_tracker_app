import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class Contest {
  final String title;
  final DateTime startTime;
  final Duration duration;
  final String platform;
  final String? url;

  Contest({
    required this.title,
    required this.startTime,
    required this.duration,
    required this.platform,
    this.url,
  });

  factory Contest.fromJson(Map<String, dynamic> json, String platform) {
    if (platform == 'Codeforces') {
      return Contest(
        title: json['name'],
        startTime: DateTime.fromMillisecondsSinceEpoch(json['startTimeSeconds'] * 1000),
        duration: Duration(seconds: json['durationSeconds']),
        platform: platform,
        url: 'https://codeforces.com/contests/${json['id']}',
      );
    } else {
      // LeetCode / Other
      return Contest(
        title: json['title'] ?? 'Contest',
        startTime: DateTime.fromMillisecondsSinceEpoch((json['startTime'] ?? 0) * 1000),
        duration: Duration(seconds: json['duration'] ?? 5400),
        platform: platform,
        url: json['url'],
      );
    }
  }
}

class ContestService {
  Future<List<Contest>> fetchUpcomingContests() async {
    final List<Contest> contests = [];

    final cfUrl = Uri.parse('https://codeforces.com/api/contest.list?gym=false');
    
    try {
      final response = await http.get(cfUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List list = data['result'];
          contests.addAll(list
              .where((c) => c['phase'] == 'BEFORE')
              .map((c) => Contest.fromJson(c, 'Codeforces')));
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch Codeforces contests: $e");
    }

    // Sort by start time
    contests.sort((a, b) => a.startTime.compareTo(b.startTime));
    return contests;
  }
}
