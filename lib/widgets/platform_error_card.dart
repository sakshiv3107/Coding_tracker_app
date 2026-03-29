import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

class PlatformErrorCard extends StatelessWidget {
  final String platformName;
  final String message;
  final VoidCallback onRetry;
  final bool isUserNotFound;

  const PlatformErrorCard({
    super.key,
    required this.platformName,
    required this.message,
    required this.onRetry,
    this.isUserNotFound = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      padding: const EdgeInsets.all(24),
      isGlass: true,
      showShadow: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isUserNotFound ? Icons.person_off_rounded : Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isUserNotFound ? 'User Not Found' : 'Connection Error',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  context: context,
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                  isPrimary: !isUserNotFound,
                ),
              ),
              if (isUserNotFound) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildButton(
                    context: context,
                    label: 'Edit Profile',
                    icon: Icons.edit_note_rounded,
                    onPressed: () => Navigator.pushNamed(context, '/edit_profile'),
                    isPrimary: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primary : AppTheme.primary.withOpacity(0.1),
        foregroundColor: isPrimary ? Colors.white : AppTheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
