import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NotConnectedWidget extends StatelessWidget {
  final String platformName;
  final dynamic icon;
  final Color color;

  const NotConnectedWidget({
    super.key,
    required this.platformName,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: icon is IconData 
                  ? Icon(icon, size: 80, color: color.withOpacity(0.2))
                  : FaIcon(icon, size: 80, color: color.withOpacity(0.2)),
              ),
              const SizedBox(height: 32),
              Text(
                '$platformName Not Connected',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Connect your $platformName account to track your progress, analyze your coding patterns, and compete with others.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/edit_profile');
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Connect in Profile Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
