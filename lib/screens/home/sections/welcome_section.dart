import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class WelcomeSection extends StatelessWidget {
  final String userName;
  final ThemeData theme;
  final bool isSmallScreen;

  const WelcomeSection({
    super.key,
    required this.userName,
    required this.theme,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile Image with ring
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryMint, width: 2),
          ),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryMintLight,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppTheme.primaryMint,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMintLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PRO TIER',
                      style: TextStyle(
                        color: AppTheme.primaryMint,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Notification Bell
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded, color: AppTheme.primaryMint),
        ),
      ],
    );
  }
}
