import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double? borderOpacity;
  final bool showBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.width,
    this.height,
    this.onTap,
    this.gradient,
    this.borderOpacity,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    BoxDecoration decoration;
    if (isDark) {
      decoration = AppTheme.glassCardDark(
        borderRadius: BorderRadius.circular(borderRadius),
        borderOpacity: borderOpacity ?? 0.1,
      );
    } else {
      decoration = AppTheme.glassCardLight(
        borderRadius: BorderRadius.circular(borderRadius),
        borderOpacity: borderOpacity ?? 0.15,
      );
    }

    if (gradient != null) {
      decoration = decoration.copyWith(gradient: gradient);
    }

    if (!showBorder) {
      decoration = decoration.copyWith(border: Border.all(color: Colors.transparent));
    }
    
    Widget content = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}


