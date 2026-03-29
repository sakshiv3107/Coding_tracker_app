// widgets/recent_submissions_section.dart
// LeetCode-style recent submissions list with difficulty badge,
// status indicator, language chip, and time ago label.

import 'package:flutter/material.dart';
import '../models/submission.dart';
import 'modern_card.dart';

class RecentSubmissionsSection extends StatelessWidget {
  final List<Submission> submissions;
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
    return Colors.grey.shade600;
  }

  IconData _statusIcon(String status) {
    if (status == 'Accepted') return Icons.check_circle_rounded;
    if (status.contains('Wrong')) return Icons.cancel_rounded;
    if (status.contains('Time')) return Icons.timer_off_rounded;
    if (status.contains('Memory')) return Icons.memory_rounded;
    return Icons.error_rounded;
  }

  String _statusShort(String status) {
    if (status == 'Accepted') return 'ACCEPTED';
    if (status.contains('Wrong Answer')) return 'WRONG';
    if (status.contains('Time Limit')) return 'TLE';
    if (status.contains('Memory Limit')) return 'MLE';
    if (status.contains('Runtime')) return 'ERROR';
    if (status.contains('Compile')) return 'COMPILE';
    return status.toUpperCase();
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
    if (visible.isEmpty) {
      if (showTitle) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Recent Submission History', style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            ModernCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 40, color: Colors.grey.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'No recent submissions found',
                      style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              const Icon(Icons.history_rounded, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Recent Submission History', style: theme.textTheme.titleLarge),
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

  Widget _buildRow(Submission sub, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon circle
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _statusIcon(sub.status),
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 14),

          // Title + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (sub.lang != null && sub.lang!.isNotEmpty) ...[
                      _buildInfoChip(sub.lang!, Colors.blue.shade400, isDark),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _timeAgo(sub.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  _statusShort(sub.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (sub.difficulty != null && sub.difficulty!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  sub.difficulty!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _difficultyColor(sub.difficulty!),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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
