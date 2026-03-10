// widgets/streak_card.dart
// Reusable streak card — works on both home screen and LeetCode stats screen.
// Pass compact: true on the home screen for a smaller layout.

import 'package:flutter/material.dart';
import 'modern_card.dart';
import 'animations/animated_stat_counter.dart';

class StreakCard extends StatefulWidget {
  final int currentStreak;
  final int maxStreak;
  final bool compact;

  const StreakCard({
    super.key,
    required this.currentStreak,
    required this.maxStreak,
    this.compact = false,
  });

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.compact) return _buildCompact(isDark);
    return _buildFull(isDark);
  }

  // ── Full version (LeetCode stats screen) ──────────────────────────────────

  Widget _buildFull(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildFlameCard(isDark, isCurrent: true)),
        const SizedBox(width: 12),
        Expanded(child: _buildFlameCard(isDark, isCurrent: false)),
      ],
    );
  }

  Widget _buildFlameCard(bool isDark, {required bool isCurrent}) {
    final value = isCurrent ? widget.currentStreak : widget.maxStreak;
    final isActive = isCurrent && widget.currentStreak > 0;
    final color = isCurrent
        ? (isActive ? Colors.orange : Colors.grey.shade600)
        : Colors.amber;

    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _scale,
                child: Icon(
                  isCurrent
                      ? Icons.local_fire_department_rounded
                      : Icons.emoji_events_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isCurrent ? 'CURRENT STREAK' : 'MAX STREAK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedStatCounter(
                value: value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isActive && isCurrent ? color : null,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'd',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isCurrent ? 'Consecutive days' : 'Best record',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          // Mini flame progress bar for current streak
          if (isCurrent && widget.maxStreak > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.maxStreak > 0
                    ? (widget.currentStreak / widget.maxStreak).clamp(0.0, 1.0)
                    : 0,
                minHeight: 4,
                backgroundColor: Colors.orange.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${((widget.currentStreak / widget.maxStreak.clamp(1, 99999)) * 100).toStringAsFixed(0)}% of best',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  // ── Compact version (home screen) ─────────────────────────────────────────

  Widget _buildCompact(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Current streak
          Expanded(
            child: Row(
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: widget.currentStreak > 0
                        ? Colors.orange
                        : Colors.grey.shade600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedStatCounter(
                          value: widget.currentStreak,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: widget.currentStreak > 0
                                ? Colors.orange
                                : null,
                          ),
                        ),
                        Text(
                          'd',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Current Streak',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 36,
            color: Colors.grey.withOpacity(0.15),
          ),

          const SizedBox(width: 16),

          // Max streak
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedStatCounter(
                          value: widget.maxStreak,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'd',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Max Streak',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}