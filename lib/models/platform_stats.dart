import 'submission.dart';

class PlatformStats {
  final String platform;
  final String username;
  final String? profileUrl;
  final String? avatarUrl;
  final int totalSolved;
  final String? rank;
  final int? rating;
  final int? maxRating;
  final List<Submission> recentSubmissions;
  final Map<String, dynamic> extraMetrics;

  PlatformStats({
    required this.platform,
    required this.username,
    this.profileUrl,
    this.avatarUrl,
    required this.totalSolved,
    this.rank,
    this.rating,
    this.maxRating,
    this.recentSubmissions = const [],
    this.extraMetrics = const {},
  });
}
