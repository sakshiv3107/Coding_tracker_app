// lib/widgets/insight/progress_forecast_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/insight_model.dart';

class ProgressForecastCard extends StatelessWidget {
  final int totalSolved;
  final int solvedThisMonth;
  final int daysElapsed;
  final List<CoachGoal> goals;
  final VoidCallback onAddGoal;
  final Function(CoachGoal) onRemoveGoal;

  const ProgressForecastCard({
    super.key,
    required this.totalSolved,
    required this.solvedThisMonth,
    required this.daysElapsed,
    required this.goals,
    required this.onAddGoal,
    required this.onRemoveGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyRate = daysElapsed > 0 ? solvedThisMonth / daysElapsed : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress Forecast',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              FilledButton.tonal(
                onPressed: onAddGoal,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14),
                    SizedBox(width: 4),
                    Text('Add Goal', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats summary row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat(context, '$totalSolved', 'Total Solved'),
                _divider(),
                _buildMiniStat(context, '$solvedThisMonth', 'This Month'),
                _divider(),
                _buildMiniStat(context, '${dailyRate.toStringAsFixed(1)}/day', 'Pace'),
              ],
            ),
          ),

          // Goals list
          if (goals.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(Icons.flag_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.15), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'No goals yet. Add one to track your forecast.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ...goals.map((goal) => _buildGoalRow(context, goal, dailyRate)),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildGoalRow(BuildContext context, CoachGoal goal, double dailyRate) {
    final theme = Theme.of(context);

    // Determine the current value based on goal type
    final current = goal.type == 'problems' ? totalSolved : 0;
    final progress = goal.target > 0 ? (current / goal.target).clamp(0.0, 1.0) : 0.0;
    final gap = (goal.target - current).clamp(0, 999999);
    final eta = (dailyRate > 0 && gap > 0) ? (gap / dailyRate).ceil() : null;

    Color progressColor;
    if (progress >= 0.8) progressColor = Colors.green;
    else if (progress >= 0.5) progressColor = Colors.amber;
    else progressColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: progressColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _goalIcon(goal.type, theme),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$current / ${goal.target}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onRemoveGoal(goal),
                child: Icon(Icons.close_rounded,
                    size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: progressColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          if (eta != null) ...[
            const SizedBox(height: 8),
            Text(
              eta > 0
                  ? 'At current pace: ~$eta days to goal'
                  : 'Goal reached! 🎉',
              style: TextStyle(
                fontSize: 11,
                color: eta > 0
                    ? theme.colorScheme.onSurface.withOpacity(0.45)
                    : Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _goalIcon(String type, ThemeData theme) {
    final IconData icon;
    final Color color;
    switch (type) {
      case 'rating':
        icon = Icons.star_rounded;
        color = Colors.amber;
        break;
      case 'streak':
        icon = Icons.local_fire_department_rounded;
        color = Colors.deepOrange;
        break;
      case 'custom':
        icon = Icons.edit_note_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.code_rounded;
        color = theme.colorScheme.primary;
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildMiniStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45))),
      ],
    );
  }

  Widget _divider() => Container(height: 28, width: 1, color: Colors.grey.withOpacity(0.15));
}


// ── Goal Add Bottom Sheet ──────────────────────────────────────────────────────

class AddGoalSheet extends StatefulWidget {
  final Function(CoachGoal) onAdd;

  const AddGoalSheet({super.key, required this.onAdd});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  String _selectedType = 'problems';
  String? _selectedPreset;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  bool _isCustom = false;

  static const _presets = [
    ('Solve 100 Problems', 100, 'problems'),
    ('Solve 300 Problems', 300, 'problems'),
    ('Solve 500 Problems', 500, 'problems'),
    ('Solve 1000 Problems', 1000, 'problems'),
    ('Reach 1600 Rating', 1600, 'rating'),
    ('Reach 1800 Rating', 1800, 'rating'),
    ('Maintain 30-Day Streak', 30, 'streak'),
    ('Maintain 60-Day Streak', 60, 'streak'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Add Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _isCustom = !_isCustom),
                child: Text(_isCustom ? 'Use Preset' : 'Custom Goal'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isCustom) ...[
            // Custom goal inputs
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'Goal title (e.g., "Master DP")',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Target number',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'problems', child: Text('Problems')),
                    DropdownMenuItem(value: 'rating', child: Text('Rating')),
                    DropdownMenuItem(value: 'streak', child: Text('Streak')),
                    DropdownMenuItem(value: 'custom', child: Text('Custom')),
                  ],
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final title = _titleCtrl.text.trim();
                  final target = int.tryParse(_targetCtrl.text) ?? 0;
                  if (title.isEmpty || target <= 0) return;
                  widget.onAdd(CoachGoal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title,
                    target: target,
                    type: _selectedType,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Add Goal'),
              ),
            ),
          ] else ...[
            // Preset list
            ...List.generate(_presets.length, (i) {
              final preset = _presets[i];
              final isSelected = _selectedPreset == preset.$1;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedColor: theme.colorScheme.primary,
                selectedTileColor: theme.colorScheme.primary.withOpacity(0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: Icon(_typeIcon(preset.$3), size: 18),
                title: Text(preset.$1, style: const TextStyle(fontSize: 13)),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
                onTap: () => setState(() => _selectedPreset = preset.$1),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedPreset == null ? null : () {
                  final preset = _presets.firstWhere((p) => p.$1 == _selectedPreset);
                  widget.onAdd(CoachGoal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: preset.$1,
                    target: preset.$2,
                    type: preset.$3,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Add Selected Goal'),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'rating': return Icons.star_rounded;
      case 'streak': return Icons.local_fire_department_rounded;
      default: return Icons.code_rounded;
    }
  }
}
