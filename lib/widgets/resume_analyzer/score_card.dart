import 'package:flutter/material.dart';
import '../../widgets/glassmorphic_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ScoreCard extends StatelessWidget {
  final int score;
  final String label;

  const ScoreCard({
    super.key,
    required this.score,
    this.label = "Resume Strength",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = theme.colorScheme.primary; 

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: scoreColor.withOpacity(0.1),
                  color: scoreColor,
                  strokeCap: StrokeCap.round,
                ).animate().custom(
                  duration: 1500.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => CircularProgressIndicator(
                    value: value * (score / 100),
                    strokeWidth: 8,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    color: scoreColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$score",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  Text(
                    "/100",
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getScoreFeedback(score),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreFeedback(int score) {
    if (score >= 85) return "Excellent score! Your resume matches industry standards perfectly.";
    if (score >= 70) return "Good resume. Some minor optimizations could further boost your visibility.";
    if (score >= 50) return "Average. Focus on adding more specific technical milestones.";
    return "Needs work. Follow the AI suggestions below to strengthen your profile.";
  }
}
