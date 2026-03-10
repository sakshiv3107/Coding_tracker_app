// widgets/recent_submissions_section.dart
// LeetCode-style recent submissions list with difficulty badge,
// status indicator, language chip, and time ago label.

import 'package:flutter/material.dart';
import '../models/leetcode_stats.dart';
import 'modern_card.dart';

class RecentSubmissionsSection extends StatelessWidget {
  final List<RecentSubmission> submissions;
  // How many to show — use 5 for stats screen, 3 for home screen
  final int limit;
  final bool showTitle;

  const RecentSubmissionsSection({
    super.key,
    required this.submissions,
    this.limit = 5,
    this.showTitle = true,
  });

  // ── helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    if (status == 'Accepted') return const Color(0xFF00C9A7);
    if (status.contains('Wrong')) return const Color(0xFFFF6B7A);
    if (status.contains('Time')) return const Color(0xFFFFA552);
    if (status.contains('Memory')) return const Color(0xFF6C63FF);
    if (status.contains('Runtime')) return const Color(0xFFFF6B7A);
    return Colors.grey;
  }

  IconData _statusIcon(String status) {
    if (status == 'Accepted') return Icons.check_circle_rounded;
    if (status.contains('Wrong')) return Icons.cancel_rounded;
    if (status.contains('Time')) return Icons.timer_off_rounded;
    if (status.contains('Memory')) return Icons.memory_rounded;
    return Icons.error_rounded;
  }

  String _statusShort(String status) {
    if (status == 'Accepted') return 'AC';
    if (status.contains('Wrong Answer')) return 'WA';
    if (status.contains('Time Limit')) return 'TLE';
    if (status.contains('Memory Limit')) return 'MLE';
    if (status.contains('Runtime')) return 'RE';
    if (status.contains('Compile')) return 'CE';
    return status.substring(0, status.length.clamp(0, 3)).toUpperCase();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final visible = submissions.take(limit).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20),
              const SizedBox(width: 8),
              Text('Recent Submissions', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
        ],
        ModernCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: visible.asMap().entries.map((entry) {
              final i = entry.key;
              final sub = entry.value;
              final color = _statusColor(sub.status);
              final isLast = i == visible.length - 1;

              return Column(
                children: [
                  _buildRow(sub, color, isDark),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.06),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(RecentSubmission sub, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Status icon circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(sub.status),
              color: color,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          // Title + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      _timeAgo(sub.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (sub.difficulty.isNotEmpty) ...[
                      Text(
                        ' · ',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      Text(
                        sub.difficulty,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _difficultyColor(sub.difficulty),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusShort(sub.status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF00C9A7);
      case 'medium':
        return const Color(0xFFFFA552);
      case 'hard':
        return const Color(0xFFFF6B7A);
      default:
        return Colors.grey;
    }
  }
}