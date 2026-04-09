// lib/widgets/insight/mistake_pattern_card.dart
import 'package:flutter/material.dart';
import '../../models/insight_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MistakePatternSection extends StatelessWidget {
  final List<MistakePattern> patterns;
  final Function(String patternName) onGetTip;
  final Map<String, bool> tipLoadingState;

  const MistakePatternSection({
    super.key,
    required this.patterns,
    required this.onGetTip,
    required this.tipLoadingState,
  });

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mistake Pattern Analysis",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...patterns.map((p) => _buildMistakeCard(context, p)),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMistakeCard(BuildContext context, MistakePattern p) {
    final theme = Theme.of(context);
    final isLoadingTip = tipLoadingState[p.patternName] ?? false;

    Color severityColor;
    switch (p.severity) {
      case 'red':   severityColor = Colors.red; break;
      case 'amber': severityColor = Colors.amber; break;
      case 'blue':  severityColor = Colors.blue; break;
      default:      severityColor = Colors.grey;
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
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: severityColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: severityColor.withOpacity(0.4), blurRadius: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.patternName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      "Detected in ${p.count} recent submissions",
                      style: TextStyle(
                        fontSize: 11, 
                        color: theme.colorScheme.onSurface.withOpacity(0.5)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (p.aiTip != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        "Coach Tip",
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          color: theme.colorScheme.primary
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.aiTip!,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoadingTip ? null : () => onGetTip(p.patternName),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
                child: isLoadingTip
                    ? const SizedBox(
                        height: 12, 
                        width: 12, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Text("Get coaching tip", style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: theme.colorScheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "No mistake patterns detected",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Connect more accounts or solve more problems to see patterns.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
