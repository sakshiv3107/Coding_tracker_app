// lib/widgets/insight/progress_forecast_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProgressForecastCard extends StatelessWidget {
  final int totalSolved;
  final int solvedThisMonth;
  final int daysElapsed;
  final String? currentGoalTitle;
  final int? currentGoalTarget;
  final VoidCallback onSelectGoal;

  const ProgressForecastCard({
    super.key,
    required this.totalSolved,
    required this.solvedThisMonth,
    required this.daysElapsed,
    this.currentGoalTitle,
    this.currentGoalTarget,
    required this.onSelectGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final dailyRate = daysElapsed > 0 ? solvedThisMonth / daysElapsed : 0.0;
    final hasGoal = currentGoalTarget != null;
    
    final progress = hasGoal ? (totalSolved / currentGoalTarget!).clamp(0.0, 1.0) : 0.0;
    final gap = hasGoal ? (currentGoalTarget! - totalSolved).clamp(0, 999999) : 0;
    final estimatedDays = (hasGoal && dailyRate > 0) ? (gap / dailyRate).ceil() : 0;

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
                "Progress Forecast",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onSelectGoal,
                child: Text(hasGoal ? "Change Goal" : "Set Goal", style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (!hasGoal) ...[
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Icon(Icons.flag_outlined, color: theme.colorScheme.onSurface.withOpacity(0.2), size: 32),
                  const SizedBox(height: 8),
                  const Text("Set a target to see your forecast", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentGoalTitle ?? "Target Goal",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                   "$totalSolved / $currentGoalTarget",
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    context, 
                    "Daily Rate", 
                    "${dailyRate.toStringAsFixed(1)} solved/day"
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  if (dailyRate > 0)
                    _buildStatRow(
                      context, 
                      "Est. Target Reach", 
                      "~$estimatedDays days",
                      highlight: true
                    )
                  else
                    _buildStatRow(
                      context, 
                      "Notice", 
                      "No activity this month yet"
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (gap > 0 && dailyRate > 0)
              Text(
                "Tip: Solve ${(gap / (estimatedDays * 0.8)).ceil()} problems/day to reach it in ${(estimatedDays * 0.8).ceil()} days.",
                style: TextStyle(
                  fontSize: 11, 
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic
                ),
              ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildStatRow(BuildContext context, String label, String value, {bool highlight = false}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(
          value, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight ? theme.colorScheme.primary : null
          )
        ),
      ],
    );
  }
}
