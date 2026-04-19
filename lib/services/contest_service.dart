import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Contest {
  final String? id;
  final String title;
  final DateTime startTime;
  final Duration duration;
  final String platform;
  final String? url;

  Contest({
    this.id,
    required this.title,
    required this.startTime,
    required this.duration,
    required this.platform,
    this.url,
  });

  bool get startsSoon {
    final diff = startTime.difference(DateTime.now());
    return diff.inHours < 24 && diff.inHours >= 0;
  }

  factory Contest.fromJson(Map<String, dynamic> json, String platform) {
    if (platform == 'Codeforces') {
      return Contest(
        id: json['id']?.toString(),
        title: json['name'],
        startTime:
            DateTime.fromMillisecondsSinceEpoch(json['startTimeSeconds'] * 1000),
        duration: Duration(seconds: json['durationSeconds']),
        platform: platform,
        url: 'https://codeforces.com/contests/${json['id']}',
      );
    } else if (platform == 'CodeChef') {
      // CodeChef API format
      final startStr = json['contest_start_date_iso'] ?? json['contest_start_date'] ?? '';
      DateTime start;
      try {
        start = DateTime.parse(startStr);
      } catch (_) {
        start = DateTime.now().add(const Duration(days: 1));
      }

      int durMin = 0;
      try {
        durMin = int.tryParse(json['contest_duration']?.toString() ?? '0') ?? 180;
      } catch (_) {
        durMin = 180;
      }

      return Contest(
        id: json['contest_code'],
        title: json['contest_name'] ?? 'CodeChef Contest',
        startTime: start,
        duration: Duration(minutes: durMin),
        platform: platform,
        url: 'https://www.codechef.com/${json['contest_code']}',
      );
    } else {
      // LeetCode / Other
      final startTs = (json['startTime'] is int)
          ? json['startTime']
          : int.tryParse(json['startTime'].toString()) ?? 0;

      return Contest(
        id: json['titleSlug'] ?? json['id']?.toString(),
        title: json['title'] ?? 'Contest',
        startTime: DateTime.fromMillisecondsSinceEpoch(startTs * 1000),
        duration: Duration(seconds: json['duration'] ?? 5400),
        platform: platform,
        url: json['url'] ??
            (json['titleSlug'] != null
                ? 'https://leetcode.com/contest/${json['titleSlug']}'
                : null),
      );
    }
  }
}

class ContestService {
  Future<List<Contest>> fetchUpcomingContests() async {
    final List<Contest> contests = [];

    final results = await Future.wait([
      _fetchCodeforces(),
      _fetchCodeChef(),
      _fetchLeetCode(),
    ]);

    for (var r in results) {
      contests.addAll(r);
    }

    // Filter past contests and duplicates
    final now = DateTime.now();
    final unique = <String, Contest>{};
    for (var c in contests) {
      if (c.startTime.isAfter(now.subtract(const Duration(hours: 2)))) {
        final key = '${c.platform}_${c.startTime.millisecondsSinceEpoch}_${c.title}';
        unique[key] = c;
      }
    }

    final finalContests = unique.values.toList();
    finalContests.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Schedule notifications
    await scheduleAllContestNotifications(finalContests);
    
    return finalContests;
  }

  Future<void> scheduleAllContestNotifications(List<Contest> contests) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('contest_reminders_enabled') ?? true;
    if (!enabled) return;

    final platforms = prefs.getStringList('contest_platforms') ?? ['leetcode', 'codeforces', 'codechef'];

    for (var contest in contests) {
      if (contest.startTime.isAfter(DateTime.now())) {
        // Platform match check (case insensitive)
        final pMatch = platforms.any((p) => p.toLowerCase() == contest.platform.toLowerCase());
        if (!pMatch) continue;

        await NotificationService.instance.scheduleContestReminders(
          contestId: contest.id ?? contest.startTime.millisecondsSinceEpoch.toString(),
          platform: contest.platform,
          contestName: contest.title,
          startTime: contest.startTime,
          contestUrl: contest.url ?? '',
        );
      }
    }
  }

  Future<List<Contest>> _fetchCodeforces() async {
    final cfUrl = Uri.parse('https://codeforces.com/api/contest.list?gym=false');
    try {
      final response = await http.get(cfUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['status'] == 'OK' && data['result'] is List) {
          final List list = data['result'];
          final List<Contest> contests = [];
          for (var c in list) {
            try {
              if (c['phase'] == 'BEFORE') {
                 contests.add(Contest.fromJson(c, 'Codeforces'));
              }
            } catch (e) {
               debugPrint("Error parsing CF contest: $e");
            }
          }
          return contests;
        }
      }
    } catch (e) {
      debugPrint("CF contests error: $e");
    }
    return [];
  }

  Future<List<Contest>> _fetchCodeChef() async {
    final ccUrl = Uri.parse('https://www.codechef.com/api/list/contests/all?sort_by=START&sorting_order=asc');
    try {
      final response = await http.get(ccUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          final List future = data['future_contests'] ?? [];
          final List present = data['present_contests'] ?? [];
          
          final List<Contest> contests = [];
          for (var c in [...present, ...future]) {
            try {
              contests.add(Contest.fromJson(c, 'CodeChef'));
            } catch (e) {
               debugPrint("Error parsing CC contest: $e");
            }
          }
          return contests;
        }
      }
    } catch (e) {
      debugPrint("CodeChef contests error: $e");
    }
    return [];
  }

  Future<List<Contest>> _fetchLeetCode() async {
    final lcUrl = Uri.parse('https://leetcode.com/graphql');
    final query = {
      "query": """
        {
          allContests {
            title
            titleSlug
            startTime
            duration
          }
        }
      """
    };

    try {
      final response = await http.post(
        lcUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(query),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] != null && data['data']['allContests'] is List) {
          final List list = data['data']['allContests'];
          final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          
          final List<Contest> contests = [];
          for (var c in list) {
            try {
              final int start = (c['startTime'] is int) ? c['startTime'] : (int.tryParse(c['startTime']?.toString() ?? '0') ?? 0);
              final int duration = (c['duration'] is int) ? c['duration'] : (int.tryParse(c['duration']?.toString() ?? '0') ?? 0);
              
              if (start + duration > now) {
                contests.add(Contest.fromJson(c, 'LeetCode'));
              }
            } catch (e) {
               debugPrint("Error parsing LC contest: $e");
            }
          }
          return contests;
        }
      }
    } catch (e) {
      debugPrint("LeetCode contests error: $e");
    }
    return [];
  }

  Future<List<Contest>> fetchAttendedContests({String? cfHandle, String? lcHandle}) async {
    final List<Contest> attended = [];
    
    final futures = <Future<List<Contest>>>[];
    if (cfHandle != null && cfHandle.isNotEmpty) futures.add(_fetchCodeforcesHistory(cfHandle));
    if (lcHandle != null && lcHandle.isNotEmpty) futures.add(_fetchLeetCodeHistory(lcHandle));
    
    final results = await Future.wait(futures);
    for (var r in results) {
      attended.addAll(r);
    }
    
    attended.sort((a, b) => b.startTime.compareTo(a.startTime)); // Newest first
    return attended;
  }

  Future<List<Contest>> _fetchCodeforcesHistory(String handle) async {
    final url = Uri.parse('https://codeforces.com/api/user.rating?handle=$handle');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final List list = data['result'];
          return list.map((c) => Contest(
            id: c['contestId'].toString(),
            title: c['contestName'],
            startTime: DateTime.fromMillisecondsSinceEpoch(c['ratingUpdateTimeSeconds'] * 1000),
            duration: const Duration(hours: 2), // Approximation
            platform: 'Codeforces',
            url: 'https://codeforces.com/contest/${c['contestId']}',
          )).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<Contest>> _fetchLeetCodeHistory(String handle) async {
    final url = Uri.parse('https://leetcode.com/graphql');
    final query = {
      "query": """
        query userContestRankingHistory(\$username: String!) {
          userContestRankingHistory(username: \$username) {
            attended
            contest {
              title
              startTime
            }
          }
        }
      """,
      "variables": {"username": handle}
    };
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(query),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = (data['data'] != null) ? (data['data']['userContestRankingHistory'] ?? []) : [];
        return list.where((e) => e != null && e['attended'] == true && e['contest'] != null).map((e) {
          final c = e['contest'];
          return Contest(
            title: c['title'] ?? 'LeetCode Contest',
            startTime: DateTime.fromMillisecondsSinceEpoch((c['startTime'] ?? 0) * 1000),
            duration: const Duration(minutes: 90),
            platform: 'LeetCode',
            url: 'https://leetcode.com/contest/${(c['title'] ?? '').toString().toLowerCase().replaceAll(' ', '-')}',
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}


