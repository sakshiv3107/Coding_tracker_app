// models/developer_score.dart

class DeveloperScore {
  final double score;
  final int totalProblems;
  final double contestRating;
  final int githubStars;
  final int totalCommits;

  DeveloperScore({
    required this.score,
    required this.totalProblems,
    required this.contestRating,
    required this.githubStars,
    required this.totalCommits,
  });

  /// DevScore = (problems × 1.5) + (rating / 10) + (stars × 3) + (commits / 50)
  factory DeveloperScore.calculate({
    required int totalProblems,
    required double contestRating,
    required int githubStars,
    required int totalCommits,
  }) {
    final score = (totalProblems * 1.5) +
        (contestRating / 10) +
        (githubStars * 3) +
        (totalCommits / 50);

    return DeveloperScore(
      score: score,
      totalProblems: totalProblems,
      contestRating: contestRating,
      githubStars: githubStars,
      totalCommits: totalCommits,
    );
  }

  String get level {
    if (score >= 600) return 'Expert Developer';
    if (score >= 300) return 'Advanced Developer';
    if (score >= 100) return 'Intermediate Developer';
    return 'Beginner Developer';
  }

  double get normalizedScore {
    // Normalize to 0-1 for UI (cap at 1200 as max)
    return (score / 1200).clamp(0.0, 1.0);
  }

  /// Breakdown percentages for bar chart
  double get problemsContribution => totalProblems * 1.5;
  double get ratingContribution => contestRating / 10;
  double get starsContribution => githubStars * 3;
  double get commitsContribution => totalCommits / 50;

  double get totalContributions =>
      problemsContribution + ratingContribution + starsContribution + commitsContribution;
}


