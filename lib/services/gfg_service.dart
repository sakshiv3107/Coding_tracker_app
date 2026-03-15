import '../models/platform_stats.dart';

class GfgService {
  Future<PlatformStats> fetchData(String username) async {
    // GeeksforGeeks usually requires scraping. 
    // For this implementation, we simulate fetching data.
    // In a real app, you'd use a backend proxy or a scraper service.
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate successful fetch with mock data
    return PlatformStats(
      platform: "GeeksforGeeks",
      username: username,
      totalSolved: 450,
      rank: "Global Rank: 1245",
      rating: 1850,
      extraMetrics: {
        "score": 1540,
        "monthlyRank": 45,
        "instituteRank": 12,
      },
    );
  }
}
