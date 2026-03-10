import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/goal_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/modern_card.dart';
import '../../widgets/animations/fade_slide_transition.dart';
import '../../models/goal.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalProvider = context.watch<GoalProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Goals', style: theme.textTheme.headlineMedium),
                    IconButton.filledTonal(
                      onPressed: () => _showAddGoalDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (goalProvider.goals.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.track_changes_rounded, size: 80, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text('No active goals', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      const SizedBox(height: 8),
                      Text('Set a goal to track your progress!', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goalProvider.goals[index];
                      return FadeSlideTransition(
                        delay: Duration(milliseconds: index * 100),
                        child: _GoalCard(goal: goal),
                      );
                    },
                    childCount: goalProvider.goals.length,
                  ),
                ),
              ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    // Basic implementation for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Goal creation coming soon!')),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = goal.type == 'leetcode' ? AppTheme.leetCodeYellow : AppTheme.githubBlack;
    final icon = goal.type == 'leetcode' ? Icons.code_rounded : Icons.code_off_rounded;
    final timeLeft = goal.deadline.difference(DateTime.now());
    final daysLeft = timeLeft.inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        padding: const EdgeInsets.all(24),
        showShadow: true,
        showBorder: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Ends in ${daysLeft > 0 ? '$daysLeft days' : 'a few hours'}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(goal.progress * 100).toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold),
                ),
                Text(
                  '${goal.currentValue} / ${goal.targetValue}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.progress),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
