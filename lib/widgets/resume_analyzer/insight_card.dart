import 'package:flutter/material.dart';
import '../../widgets/glassmorphic_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InsightCard extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String explanation;
  final Color? iconColor;

  const InsightCard({
    super.key,
    required this.icon,
    this.title,
    required this.explanation,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.secondary;

    return GlassmorphicContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title!.isNotEmpty) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                _buildFormattedText(theme, explanation),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildFormattedText(ThemeData theme, String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmedLine = line.trim();
        final isMistake = trimmedLine.startsWith('•') || trimmedLine.startsWith('-');
        final isSuggestion = trimmedLine.startsWith('->');

        if (isMistake) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line.replaceFirst(RegExp(r'^([•-]|->)\s*'), '').trim(),
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.95),
                height: 1.4,
              ),
            ),
          );
        } else if (isSuggestion) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: Text(
              line.replaceFirst(RegExp(r'^([•-]|->)\s*'), '').trim(),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.75),
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }
}
