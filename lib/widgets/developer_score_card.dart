// widgets/developer_score_card.dart
// Flat named params — matches dashboard_screen.dart call site exactly.

import 'package:flutter/material.dart';
import '../models/developer_score.dart';
import 'modern_card.dart';
import 'animations/animated_stat_counter.dart';

class DeveloperScoreCard extends StatefulWidget {
  final int totalSolved;
  final double leetcodeRating;
  final int githubStars;
  final int githubContributions;

  const DeveloperScoreCard({
    super.key,
    required this.totalSolved,
    required this.leetcodeRating,
    required this.githubStars,
    required this.githubContributions,
  });

  @override
  State<DeveloperScoreCard> createState() => _DeveloperScoreCardState();
}

class _DeveloperScoreCardState extends State<DeveloperScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  late DeveloperScore _score;

  @override
  void initState() {
    super.initState();
    _score = _compute();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(DeveloperScoreCard old) {
    super.didUpdateWidget(old);
    if (old.totalSolved != widget.totalSolved ||
        old.leetcodeRating != widget.leetcodeRating ||
        old.githubStars != widget.githubStars ||
        old.githubContributions != widget.githubContributions) {
      _score = _compute();
      _controller
        ..reset()
        ..forward();
    }
  }

  DeveloperScore _compute() => DeveloperScore.calculate(
        totalProblems: widget.totalSolved,
        contestRating: widget.leetcodeRating,
        githubStars: widget.githubStars,
        totalCommits: widget.githubContributions,
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (_score.level) {
      case 'Advanced Developer':
        return const Color(0xFF6C63FF);
      case 'Intermediate Developer':
        return const Color(0xFF00C9A7);
      default:
        return const Color(0xFFFFA552);
    }
  }

  IconData get _icon {
    switch (_score.level) {
      case 'Advanced Developer':
        return Icons.workspace_premium_rounded;
      case 'Intermediate Developer':
        return Icons.trending_up_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color;

    return ModernCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                : [color.withOpacity(0.08), color.withOpacity(0.02)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVELOPER SCORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        _score.level,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedStatCounter(
                  value: _score.score.toInt(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Overall progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  '${(_score.normalizedScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _anim,
              builder: (context, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _score.normalizedScore * _anim.value,
                  minHeight: 10,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Breakdown bars
            _buildBreakdown(color),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdown(Color color) {
    final total = _score.totalContributions;
    if (total == 0) return const SizedBox.shrink();

    final items = [
      (label: 'Solved',   value: _score.problemsContribution, color: const Color(0xFFFFA552), icon: Icons.code_rounded),
      (label: 'Rating',   value: _score.ratingContribution,   color: const Color(0xFF00C9A7), icon: Icons.emoji_events_rounded),
      (label: 'Stars',    value: _score.starsContribution,    color: const Color(0xFFFFD700), icon: Icons.star_rounded),
      (label: 'Commits',  value: _score.commitsContribution,  color: const Color(0xFF6C63FF), icon: Icons.commit_rounded),
    ];

    return Column(
      children: items.map((item) {
        final fraction = item.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(item.icon, size: 14, color: item.color),
              const SizedBox(width: 8),
              SizedBox(
                width: 58,
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction * _anim.value,
                      minHeight: 6,
                      backgroundColor: item.color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(item.color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 36,
                child: Text(
                  item.value.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item.color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}