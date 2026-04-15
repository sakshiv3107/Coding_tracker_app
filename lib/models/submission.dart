class Submission {
  final String title;
  final String? titleSlug;
  final String? difficulty;
  final String status;
  final String? lang;
  final DateTime timestamp;

  Submission({
    required this.title,
    this.titleSlug,
    this.difficulty,
    required this.status,
    this.lang,
    required this.timestamp,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      title: json['title'] ?? json['problemName'] ?? 'Unknown',
      titleSlug: json['titleSlug'],
      difficulty: json['difficulty'],
      status: json['status'] ?? json['verdict'] ?? 'Unknown',
      lang: json['lang'] ?? json['language'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] is int ? json['timestamp'] * 1000 : (int.tryParse(json['timestamp'].toString()) ?? 0) * 1000,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'titleSlug': titleSlug,
      'difficulty': difficulty,
      'status': status,
      'lang': lang,
      'timestamp': timestamp.millisecondsSinceEpoch ~/ 1000,
    };
  }
}


