import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user_platform_data.dart';
import '../theme/app_theme.dart';
import 'modern_card.dart';

class PlatformCard extends StatelessWidget {
  final UserPlatformData data;
  final VoidCallback? onTap;

  const PlatformCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ModernCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      isGlass: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: data.icon is IconData 
                  ? Icon(data.icon, color: data.color, size: 24)
                  : FaIcon(data.icon, color: data.color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: data.isConnected 
                      ? Colors.green.withValues(alpha: 0.1) 
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.isConnected ? Icons.check_circle : Icons.error_outline,
                      size: 12,
                      color: data.isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.isConnected ? 'Connected' : 'Not Linked',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: data.isConnected ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.platformName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          Text(
            data.username,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryDark.withValues(alpha: 0.4),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStat(
                context,
                label: data.platformName=='GitHub'?'COMMITS':'SOLVED',
                value: data.solvedCount.toString(),
                icon: Icons.done_all_rounded,
              ),
              if (data.rating != null) ...[
                const SizedBox(width: 24),
                _buildStat(
                  context,
                  label: 'RATING',
                  value: data.rating.toString(),
                  icon: Icons.trending_up_rounded,
                ),
              ],
            ],
          ),
          if (data.ranking != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   Icon(Icons.military_tech_rounded, size: 16, color: data.color),
                  const SizedBox(width: 8),
                  Text(
                    data.ranking!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: data.color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, {required String label, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondaryDark.withValues(alpha: 0.3)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: AppTheme.textSecondaryDark.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
