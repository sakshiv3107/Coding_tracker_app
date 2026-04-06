import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotificationSettingsTile extends StatefulWidget {
  const NotificationSettingsTile({super.key});

  @override
  State<NotificationSettingsTile> createState() => _NotificationSettingsTileState();
}

class _NotificationSettingsTileState extends State<NotificationSettingsTile> {
  bool _masterEnabled = true;
  bool _leetcodeEnabled = true;
  bool _codeforcesEnabled = true;
  bool _codechefEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final master = await NotificationService.isEnabled();
    final leetcode = await NotificationService.isPlatformEnabled('LeetCode');
    final codeforces = await NotificationService.isPlatformEnabled('Codeforces');
    final codechef = await NotificationService.isPlatformEnabled('CodeChef');

    setState(() {
      _masterEnabled = master;
      _leetcodeEnabled = leetcode;
      _codeforcesEnabled = codeforces;
      _codechefEnabled = codechef;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    
    return Column(
      children: [
        SwitchListTile.adaptive(
          title: const Text(
            'Enable Contest Notifications',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          subtitle: const Text(
            'Get alerts 1h and 10m before contests',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          value: _masterEnabled,
          activeColor: AppTheme.primary,
          onChanged: (val) {
            setState(() => _masterEnabled = val);
            NotificationService.setNotificationsEnabled(val);
          },
        ),
        if (_masterEnabled) ...[
          const Divider(indent: 16, endIndent: 16, height: 1),
          _buildPlatformToggle(
            'LeetCode', 
            FontAwesomeIcons.code, 
            AppTheme.leetCodeYellow, 
            _leetcodeEnabled,
            (val) {
              setState(() => _leetcodeEnabled = val);
              NotificationService.setPlatformEnabled('LeetCode', val);
            }
          ),
          _buildPlatformToggle(
            'Codeforces', 
            FontAwesomeIcons.bolt, 
            AppTheme.primary, 
            _codeforcesEnabled,
            (val) {
              setState(() => _codeforcesEnabled = val);
              NotificationService.setPlatformEnabled('Codeforces', val);
            }
          ),
          _buildPlatformToggle(
            'CodeChef', 
            FontAwesomeIcons.mortarBoard, 
            const Color(0xFF5B4638), 
            _codechefEnabled,
            (val) {
              setState(() => _codechefEnabled = val);
              NotificationService.setPlatformEnabled('CodeChef', val);
            }
          ),
        ],
      ],
    );
  }

  Widget _buildPlatformToggle(String name, dynamic icon, Color color, bool value, Function(bool) onChanged) { // Changed to dynamic
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch.adaptive(
              value: value,
              activeColor: color,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
