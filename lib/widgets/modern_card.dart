import 'dart:ui';
import 'package:flutter/material.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;
  final bool isGlass;
  final EdgeInsetsGeometry? margin;
  final List<Color>? gradient;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.showBorder = true,
    this.showShadow = false,
    this.onTap,
    this.isGlass = false,
    this.gradient,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColor = color ?? Theme.of(context).cardTheme.color;
    final effectiveBorderRadius = BorderRadius.circular(borderRadius ?? 24);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        border: showBorder
            ? Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              )
            : null,
        gradient: gradient != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient!,
              )
            : null,
      ),
      child: child,
    );

    if (isGlass) {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: (color ?? (isDark ? Colors.white : Colors.black))
                .withOpacity(isDark ? 0.05 : 0.01),
            child: content,
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: effectiveBorderRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.indigo.shade900)
                      .withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: -5,
                )
              ]
            : null,
      ),
      child: Material(
        color: isGlass ? Colors.transparent : themeColor,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: content,
        ),
      ),
    );
  }
}


