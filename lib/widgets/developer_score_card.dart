import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'modern_card.dart';
import 'animations/animated_stat_counter.dart';

class DeveloperScoreCard extends StatefulWidget {
  final int leetcodeSolved;
  final double leetcodeRating;
  final int githubStars;
  final int githubContributions;

  const DeveloperScoreCard({
    super.key,
    required this.leetcodeSolved,
    required this.leetcodeRating,
    required this.githubStars,
    required this.githubContributions,
  });

  @override
  State<DeveloperScoreCard> createState() => _DeveloperScoreCardState();
}

class _DeveloperScoreCardState extends State<DeveloperScoreCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int get score {
    final s = (widget.leetcodeSolved * 2) +
        (widget.leetcodeRating / 10) +
        (widget.githubStars * 3) +
        (widget.githubContributions / 50);
    return s.round();
  }

  String get rank {
    if (score < 500) return 'Beginner Developer';
    if (score < 1500) return 'Intermediate Developer';
    return 'Advanced Developer';
  }

  Color get scoreColor {
    if (score < 500) return Colors.blueAccent;
    if (score < 1500) return AppTheme.primary;
    return AppTheme.secondary;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _animation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Normalize score for progress indicator (max 3000 for full bar)
    final progress = (score / 3000).clamp(0.0, 1.0);

    return ModernCard(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scoreColor.withOpacity(0.15),
              scoreColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVELOPER SCORE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: scoreColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedStatCounter(
                      value: score,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        fontSize: 48,
                      ) ?? const TextStyle(),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scoreColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    rank.toUpperCase(),
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress * _animation.value,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: scoreColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: scoreColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Beginner',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
                Text(
                  'Advanced',
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
