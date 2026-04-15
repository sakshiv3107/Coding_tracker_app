import 'package:flutter/foundation.dart';
import 'stats_provider.dart';

class GamificationProvider extends ChangeNotifier {
  final StatsProvider statsProvider;

  GamificationProvider(this.statsProvider);

  int get currentXP => statsProvider.xpPoints;
  int get totalSolved => statsProvider.totalSolved;

  int get level => totalSolved ~/ 25;
  
  double get progress => (currentXP % 100) / 100.0;
}


