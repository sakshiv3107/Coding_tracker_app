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
    
    // Normalize score for progress indicator (max 5000 for full circle)
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
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: progress * _animation.value,
                        strokeWidth: 12,
                        backgroundColor: scoreColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedStatCounter(
                      value: score,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                        fontSize: 36,
                      ) ?? const TextStyle(),
                    ),
                    Text(
                      'DEV SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: scoreColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your score is based on problems solved, contest performance, stars, and repository contributions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
