import 'dart:async';
import '../models/leetcode_stats.dart';

class LeetcodeService {
  Future<LeetcodeStats> fetchData(String username) async {
    await Future.delayed(const Duration(seconds: 2));

    return LeetcodeStats(totalSolved: 350, easy: 200, medium: 110, hard: 40);
  }
}
