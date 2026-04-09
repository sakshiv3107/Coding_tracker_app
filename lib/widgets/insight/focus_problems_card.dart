// lib/widgets/insight/focus_problems_card.dart
import 'package:flutter/material.dart';
import '../../models/insight_model.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FocusProblemsCard extends StatelessWidget {
  final List<FocusProblem>? problems;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;

  const FocusProblemsCard({
    super.key,
    this.problems,
    required this.isLoading,
    this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Focus Problems',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: isLoading ? null : onRefresh,
              icon: Icon(Icons.refresh_rounded, size: 18, color: theme.colorScheme.primary),
              visualDensity: VisualDensity.compact,
              tooltip: 'Refresh suggestions',
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Based on your recent submissions',
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.45)),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          ...List.generate(3, (index) => _buildShimmer(context))
        else if (errorMessage != null)
          _buildError(context)
        else if (problems == null || problems!.isEmpty)
          _buildFallback(context)
        else
          ...problems!.map((p) => _buildProblemCard(context, p)),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildProblemCard(BuildContext context, FocusProblem p) {
    final theme = Theme.of(context);

    Color diffColor;
    switch (p.difficulty.toLowerCase()) {
      case 'easy':
        diffColor = const Color(0xFF22C55E);
        break;
      case 'medium':
        diffColor = const Color(0xFFF59E0B);
        break;
      case 'hard':
        diffColor = const Color(0xFFEF4444);
        break;
      default:
        diffColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.platform,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.difficulty,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: diffColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.topicTag,
                  style: TextStyle(
                    fontSize: 9,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Problem name
          Text(
            p.problemName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          // AI reason — no button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 12,
                  color: theme.colorScheme.primary.withOpacity(0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.aiReason,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(
            'Couldn\'t fetch AI suggestions.',
            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final fallbacks = [
      FocusProblem(
        problemName: 'Two Sum', platform: 'LeetCode', difficulty: 'Easy',
        topicTag: 'Arrays', aiReason: 'A foundational array problem — great for warming up.',
        url: 'https://leetcode.com/problems/two-sum/',
      ),
      FocusProblem(
        problemName: 'Longest Substring Without Repeating Characters',
        platform: 'LeetCode', difficulty: 'Medium', topicTag: 'Sliding Window',
        aiReason: 'Builds sliding-window intuition critical for strings.',
        url: 'https://leetcode.com/problems/longest-substring-without-repeating-characters/',
      ),
      FocusProblem(
        problemName: 'Word Search', platform: 'LeetCode', difficulty: 'Medium',
        topicTag: 'Backtracking', aiReason: 'Classic backtracking — reinforces DFS on a grid.',
        url: 'https://leetcode.com/problems/word-search/',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Curated suggestions (AI offline)',
            style: TextStyle(fontSize: 11, color: Colors.grey.withOpacity(0.6)),
          ),
        ),
        ...fallbacks.map((p) => _buildProblemCard(context, p)),
      ],
    );
  }
}
