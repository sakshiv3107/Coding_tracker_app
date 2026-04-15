import 'package:flutter/material.dart';
import 'glass_card.dart';

class ResponsiveCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double iconSize;

  const ResponsiveCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.padding,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return GlassCard(
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic scaling based on available height
          final double h = constraints.maxHeight;
          final double dynamicIconSize = (h * 0.2).clamp(16.0, iconSize);
          final double valueFontSize = (h * 0.22).clamp(14.0, 24.0);
          final double labelFontSize = (h * 0.1).clamp(8.0, 10.0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: dynamicIconSize,
                color: accentColor.withOpacity(0.8),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


