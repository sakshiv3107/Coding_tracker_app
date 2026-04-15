import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _contestReminders = true;
  bool _streakWarnings = true;
  bool _milestones = true;
  List<String> _platforms = ['leetcode', 'codeforces', 'codechef'];
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _contestReminders = prefs.getBool('contest_reminders_enabled') ?? true;
      _streakWarnings = prefs.getBool('streak_warnings_enabled') ?? true;
      _milestones = prefs.getBool('milestone_notifications_enabled') ?? true;
      _platforms = prefs.getStringList('contest_platforms') ?? ['leetcode', 'codeforces', 'codechef'];
      
      final startStr = prefs.getString('quiet_hours_start') ?? "22:00";
      final endStr = prefs.getString('quiet_hours_end') ?? "08:00";
      
      _quietStart = TimeOfDay(
        hour: int.parse(startStr.split(':')[0]),
        minute: int.parse(startStr.split(':')[1]),
      );
      _quietEnd = TimeOfDay(
        hour: int.parse(endStr.split(':')[0]),
        minute: int.parse(endStr.split(':')[1]),
      );
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is List<String>) await prefs.setStringList(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
        
      ),
      body: ListView(
        children: [
          _buildSectionHeader('General Alerts'),
          SwitchListTile(
            title: const Text('Contest Reminders'),
            subtitle: const Text('Alerts 1 day, 1 hour, and 30 min before'),
            value: _contestReminders,
            onChanged: (val) {
              setState(() => _contestReminders = val);
              _saveSetting('contest_reminders_enabled', val);
            },
          ),
          if (_contestReminders) 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: ['leetcode', 'codeforces', 'codechef', 'hackerrank', 'github'].map((p) {
                  final isSelected = _platforms.contains(p);
                  return FilterChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {_platforms.add(p);}
                        else {_platforms.remove(p);}
                      });
                      _saveSetting('contest_platforms', _platforms);
                    },
                  );
                }).toList(),
              ),
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Streak Warnings'),
            subtitle: const Text('Nudges when your streak is about to break'),
            value: _streakWarnings,
            onChanged: (val) {
              setState(() => _streakWarnings = val);
              _saveSetting('streak_warnings_enabled', val);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Milestone Celebrations'),
            subtitle: const Text('Celebrate solved problems and rating jumps'),
            value: _milestones,
            onChanged: (val) {
              setState(() => _milestones = val);
              _saveSetting('milestone_notifications_enabled', val);
            },
          ),
          
          _buildSectionHeader('Quiet Hours'),
          ListTile(
            title: const Text('No notifications between'),
            subtitle: Text('${_quietStart.format(context)} - ${_quietEnd.format(context)}'),
            trailing: const Icon(Icons.access_time),
            onTap: _selectQuietHours,
          ),

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () => NotificationService.instance.cancelAllNotifications(),
              icon: const Icon(Icons.notifications_off_outlined),
              label: const Text('Clear All Pending Notifications'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _selectQuietHours() async {
    final start = await showTimePicker(context: context, initialTime: _quietStart);
    if (!mounted || start == null) return;
    
    final end = await showTimePicker(context: context, initialTime: _quietEnd);
    if (!mounted || end == null) return;

    setState(() {
      _quietStart = start;
      _quietEnd = end;
    });

    final startStr = "${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
    final endStr = "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
    
    await _saveSetting('quiet_hours_start', startStr);
    await _saveSetting('quiet_hours_end', endStr);
  }
}


