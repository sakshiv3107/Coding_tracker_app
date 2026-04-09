// lib/widgets/insight/weekly_report_card.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    if (isLoading) {
      return _buildShimmer(context);
    }

    if (report == null && errorMessage == null) {
      return _buildPlaceholder(context);
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Weekly Report Card",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                "Week ${snapshot.weekNumber}",
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, "Solved", "${snapshot.solvedThisWeek}"),
              _buildStatItem(context, "Streak", snapshot.streakDelta >= 0 ? "+${snapshot.streakDelta}" : "${snapshot.streakDelta}"),
              _buildStatItem(context, "Top Platform", snapshot.bestPlatform),
            ],
          ),
          const SizedBox(height: 24),
          if (errorMessage != null)
            _buildError(context)
          else ...[
            Text(
              report?['summary'] ?? "You've had a productive week. Keep focusing on medium problems to sharpen your algorithm skills.",
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "FOCUS: ${report?['focus'] ?? 'Target 3 Hard problems this week.'}",
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: theme.colorScheme.onSecondaryContainer
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.assessment_outlined, size: 40, color: theme.colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("Ready for your weekly wrap-up?", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onGenerate, 
            child: const Text("Generate Report", style: TextStyle(fontSize: 12))
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
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text("AI report generation failed", style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
        const SizedBox(height: 4),
        TextButton(onPressed: onGenerate, child: const Text("Retry")),
      ],
    );
  }
}
