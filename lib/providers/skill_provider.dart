import 'package:flutter/foundation.dart';
import 'stats_provider.dart';

class SkillProvider extends ChangeNotifier {
  final StatsProvider statsProvider;

  SkillProvider(this.statsProvider);

  String get weakestTopic {
    final lc = statsProvider.leetcodeStats;
    if (lc == null || lc.tagStats == null || lc.tagStats!.isEmpty) {
      return 'Arrays'; // Default if no data
    }

    // Find the topic with the minimum solved count
    String weakest = lc.tagStats!.keys.first;
    int minSolved = lc.tagStats![weakest] ?? 0;

    lc.tagStats!.forEach((tag, count) {
      if (count < minSolved) {
        minSolved = count;
        weakest = tag;
      }
    });

    return weakest;
  }
}
