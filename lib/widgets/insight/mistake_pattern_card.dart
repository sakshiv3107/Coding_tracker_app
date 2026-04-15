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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mistake Pattern Analysis',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (patterns.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${patterns.length} pattern${patterns.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'From your last 30 days of submissions',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
          ),
        ),
        const SizedBox(height: 12),

        if (patterns.isEmpty)
          _buildEmptyState(context)
        else
          ...patterns.map((p) => _buildMistakeCard(context, p)),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildMistakeCard(BuildContext context, MistakePattern p) {
    final theme = Theme.of(context);
    final isLoadingTip = tipLoadingState[p.patternName] ?? false;

    final Color severityColor;
    final String causeHint;
    switch (p.patternName) {
      case 'Time Limit Exceeded (TLE)':
        severityColor = Colors.red;
        causeHint = 'Usually caused by O(n²) loops, missing pruning, or wrong data structure choice.';
        break;
      case 'Wrong Answer (WA)':
        severityColor = Colors.amber;
        causeHint = 'Often due to edge cases, off-by-one errors, or incorrect algorithm logic.';
        break;
      case 'Runtime Error':
        severityColor = const Color(0xFF60A5FA);
        causeHint = 'Typically caused by null dereference, out-of-bounds index, or stack overflow (deep recursion).';
        break;
      case 'Memory Limit Exceeded (MLE)':
        severityColor = Colors.purple;
        causeHint = 'Check for O(n²) space usage, large memoization tables, or unnecessary data copies.';
        break;
      default:
        severityColor = Colors.grey;
        causeHint = 'Review your recent submissions for patterns.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: severityColor.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.patternName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${p.count}×',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Problems found ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.detail.isNotEmpty) ...[
                  Text(
                    'Problems affected:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.detail,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Cause hint
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 12,
                        color: severityColor.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        causeHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── AI tip or Get tip button ─────────────────────────────────────
          if (p.aiTip != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.auto_awesome_rounded, size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text('Coach Fix',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        )),
                  ]),
                  const SizedBox(height: 6),
                  Text(p.aiTip!,
                      style: const TextStyle(fontSize: 12, height: 1.5)),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLoadingTip ? null : () => onGetTip(p.patternName),
                  icon: isLoadingTip
                      ? SizedBox(
                          height: 12, width: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: severityColor))
                      : Icon(Icons.auto_awesome_rounded, size: 14, color: severityColor),
                  label: Text(
                    isLoadingTip ? 'Getting fix...' : 'Get AI fix',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: severityColor,
                    side: BorderSide(color: severityColor.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
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
      padding: const EdgeInsets.all(28),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 40, color: Colors.green.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('No repeated mistakes detected 🎉',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Solve more problems to surface error patterns.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }
}


