// lib/widgets/recently_solved_section.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/leetcode_stats.dart';
import '../models/submission.dart';
import 'modern_card.dart';

class RecentlySolvedSection extends StatelessWidget {
  final List<Submission> submissions;

  const RecentlySolvedSection({super.key, required this.submissions});

  @override
  Widget build(BuildContext context) {
    // Filter only accepted submissions
    final solved = submissions.where((s) => s.status.toUpperCase() == 'ACCEPTED' || s.status.toUpperCase() == 'AC' || s.status.toUpperCase() == 'OK').take(5).toList();

    if (solved.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Text('Recently solved', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        ...solved.map((sub) => _buildProblemCard(context, sub)),
      ],
    );
  }

  Widget _buildProblemCard(BuildContext context, Submission sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ModernCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () async {
          final url = Uri.parse('https://leetcode.com/problems/${sub.titleSlug}/');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    sub.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (sub.difficulty != null && sub.difficulty!.isNotEmpty) ...[
                        _buildDifficultyTag(sub.difficulty!),
                        const SizedBox(width: 10),
                      ],
                      Icon(Icons.link_rounded, size: 14, color: Colors.blue.shade400),
                      const SizedBox(width: 4),
                      Text(
                        'View on LeetCode',
                        style: TextStyle(
                          fontSize: 12, 
                          color: Colors.blue.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyTag(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy': color = const Color(0xFF00C9A7); break;
      case 'medium': color = const Color(0xFFFFA552); break;
      case 'hard': color = const Color(0xFFFF6B7A); break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          fontSize: 9, 
          fontWeight: FontWeight.bold, 
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
