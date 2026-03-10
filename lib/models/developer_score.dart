// models/developer_score.dart

class DeveloperScore {
  final double score;
  final int leetcodeProblems;
  final double contestRating;
  final int githubStars;
  final int totalCommits;

  DeveloperScore({
    required this.score,
    required this.leetcodeProblems,
    required this.contestRating,
    required this.githubStars,
    required this.totalCommits,
  });

  /// DevScore = (problems × 2) + (rating / 10) + (stars × 3) + (commits / 50)
  factory DeveloperScore.calculate({
    required int leetcodeProblems,
    required double contestRating,
    required int githubStars,
    required int totalCommits,
  }) {
    final score = (leetcodeProblems * 2) +
        (contestRating / 10) +
        (githubStars * 3) +
        (totalCommits / 50);

    return DeveloperScore(
      score: score,
      leetcodeProblems: leetcodeProblems,
      contestRating: contestRating,
      githubStars: githubStars,
      totalCommits: totalCommits,
    );
  }

  String get level {
    if (score >= 500) return 'Advanced Developer';
    if (score >= 150) return 'Intermediate Developer';
    return 'Beginner Developer';
  }

  double get normalizedScore {
    // Normalize to 0-1 for UI (cap at 1000 as max)
    return (score / 1000).clamp(0.0, 1.0);
  }

  /// Breakdown percentages for bar chart
  double get leetcodeContribution => leetcodeProblems * 2;
  double get ratingContribution => contestRating / 10;
  double get starsContribution => githubStars * 3;
  double get commitsContribution => totalCommits / 50;

  double get totalContributions =>
      leetcodeContribution + ratingContribution + starsContribution + commitsContribution;
}