import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Gradient? gradient;

  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blur = 10,
    this.opacity = 0.05, // Muted opacity for cleaner look
    this.padding,
    this.margin,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Use theme surface color instead of hardcoded white to match the app better
              color: isDark 
                  ? theme.colorScheme.surface.withOpacity(0.6) 
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : theme.colorScheme.primary.withOpacity(0.1),
                width: 1.0,
              ),
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
