// lib/widgets/insight/weekly_report_card.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/insight_model.dart';

class WeeklyReportCard extends StatelessWidget {
  final Map<String, String>? report; // summary, focus
  final WeeklySnapshot snapshot;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onGenerate;

  const WeeklyReportCard({
    super.key,
    this.report,
    required this.snapshot,
    required this.isLoading,
    this.errorMessage,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) return _buildShimmer(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Weekly Report',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_fmt(snapshot.weekStart)} – ${_fmt(snapshot.weekEnd)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Stats grid ────────────────────────────────────────────────────
          _buildStatsGrid(context),

          const SizedBox(height: 16),

          // ── Topics covered ────────────────────────────────────────────────
          if (snapshot.topicsCovered.isNotEmpty) ...[
            Text(
              'Topics Covered',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: snapshot.topicsCovered.map((t) => _chip(context, t)).toList(),
            ),
          ],

          // ── AI Summary ──────────────────────────────────
          if (errorMessage != null)
             _buildError(context)
          else ...[
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'AI Coach Summary',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Regenerate Summary',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report?['summary'] ?? (isLoading ? 'Analyzing week...' : 'No activity detected this week to summarize.'),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            if (report?['focus'] != null && report!['focus']!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'NEXT WEEK PLAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      report!['focus']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  // ── Stats grid ─────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        _statCell(context, '${snapshot.solvedThisWeek}', 'Solved', Icons.check_circle_outline_rounded, Colors.green),
        _statCell(context, '${snapshot.totalSubmissions}', 'Submissions', Icons.upload_outlined, Colors.blue),
        _statCell(context, '${snapshot.streakDelta}', 'Streak Days', Icons.local_fire_department_rounded, Colors.deepOrange),
        _statCell(context, '${snapshot.easyThisWeek}', 'Easy', null, const Color(0xFF22C55E)),
        _statCell(context, '${snapshot.mediumThisWeek}', 'Medium', null, const Color(0xFFF59E0B)),
        _statCell(context, '${snapshot.hardThisWeek}', 'Hard', null, const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _statCell(BuildContext context, String value, String label,
      IconData? icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.onSurface.withOpacity(0.65),
          )),
    );
  }


  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const Divider(height: 24),
        Text('AI report failed.',
            style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
        TextButton(onPressed: onGenerate, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        height: 260,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('MMM d').format(d);
}


