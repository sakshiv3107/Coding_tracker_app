import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/goal_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/github_provider.dart';
import '../../services/progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
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
                      // Empty-state illustration
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.track_changes_rounded,
                          size: 64,
                          color: AppTheme.primary.withOpacity(0.35),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No goals added yet',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set a goal to track your progress!',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.38),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // ── Add Goal CTA ──────────────────────────────────
                      FilledButton.icon(
                        onPressed: () => _showAddGoalDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Goal'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
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
                        delay: Duration(milliseconds: index * 50),
                        child: _GoalCardWrapper(goal: goal),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddGoalModal(),
    );
  }
}

class _GoalCardWrapper extends StatelessWidget {
  final Goal goal;

  const _GoalCardWrapper({required this.goal});

  @override
  Widget build(BuildContext context) {
    // We watch Stats and Github here so progress updates dynamically if pulled
    final stats = context.watch<StatsProvider>();
    final github = context.watch<GithubProvider>();

    final currentProgress = ProgressService.calculateProgress(
      goal: goal,
      statsProvider: stats,
      githubProvider: github,
    );

    return _GoalCard(goal: goal, currentValue: currentProgress);
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final int currentValue;

  const _GoalCard({required this.goal, required this.currentValue});

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Goal'),
          content: const Text('Are you sure you want to remove this goal?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      context.read<GoalProvider>().deleteGoal(goal.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGithub = goal.type == GoalType.commits;
    final color = isGithub ? AppTheme.githubBlack : AppTheme.leetCodeYellow;
    final icon = isGithub ? Icons.commit_rounded : Icons.code_rounded;
    final isDark = theme.brightness == Brightness.dark;

    final progressRatio = (currentValue / goal.targetValue).clamp(0.0, 1.0);
    final isCompleted = progressRatio >= 1.0;
    
    // Choose status color
    final statusColor = isCompleted ? Colors.green : Colors.orangeAccent;
    final actualColor = isDark && isGithub && !isCompleted ? (isCompleted ? Colors.green : Colors.blueAccent) : (isCompleted ? Colors.green : color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        
        showBorder: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actualColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: actualColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        goal.timeframe == GoalTimeframe.daily ? 'Daily Goal' : 'Weekly Goal',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progressRatio * 100).toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: actualColor, fontSize: 18),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  onPressed: () => _confirmDelete(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded, size: 14, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      isCompleted ? 'Completed' : 'In Progress',
                      style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '$currentValue / ${goal.targetValue}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progressRatio),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: actualColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(actualColor),
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

class _AddGoalModal extends StatefulWidget {
  const _AddGoalModal();

  @override
  State<_AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends State<_AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();

  GoalType _selectedType = GoalType.questions;
  GoalTimeframe _selectedTimeframe = GoalTimeframe.daily;
  String _selectedPlatform = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insets = MediaQuery.of(context).viewInsets;

    return Container(
      margin: EdgeInsets.only(top: kToolbarHeight),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + insets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Create New Goal', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g., Solve 5 questions',
                ),
                validator: (v) => v!.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<GoalType>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'Focus Area'),
                      items: const [
                        DropdownMenuItem(value: GoalType.questions, child: Text('Questions')),
                        DropdownMenuItem(value: GoalType.commits, child: Text('Commits')),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedType = v!;
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<GoalTimeframe>(
                      value: _selectedTimeframe,
                      decoration: const InputDecoration(labelText: 'Timeframe'),
                      items: const [
                        DropdownMenuItem(value: GoalTimeframe.daily, child: Text('Daily')),
                        DropdownMenuItem(value: GoalTimeframe.weekly, child: Text('Weekly')),
                      ],
                      onChanged: (v) => setState(() {
                        _selectedTimeframe = v!;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedType == GoalType.questions) ...[
                DropdownButtonFormField<String>(
                  value: _selectedPlatform,
                  decoration: const InputDecoration(labelText: 'Platform (Optional)'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Platforms')),
                    DropdownMenuItem(value: 'leetcode', child: Text('LeetCode')),
                    DropdownMenuItem(value: 'codeforces', child: Text('Codeforces')),
                    DropdownMenuItem(value: 'codechef', child: Text('CodeChef')),
                  ],
                  onChanged: (v) => setState(() {
                    _selectedPlatform = v!;
                  }),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Target Number',
                  hintText: 'e.g., 5',
                ),
                validator: (v) {
                   if (v == null || v.trim().isEmpty) return 'Required';
                   final n = int.tryParse(v);
                   if (n == null || n <= 0) return 'Must be > 0';
                   return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final goal = Goal(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _titleController.text.trim(),
                      type: _selectedType,
                      targetValue: int.parse(_targetController.text),
                      timeframe: _selectedTimeframe,
                      platform: _selectedType == GoalType.questions ? _selectedPlatform : 'github',
                      createdAt: DateTime.now(),
                    );
                    context.read<GoalProvider>().addGoal(goal);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



