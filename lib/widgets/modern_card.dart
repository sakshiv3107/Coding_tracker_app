import 'package:flutter/material.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final bool showBorder;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: color ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(borderRadius ?? 24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 24),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius ?? 24),
              border: showBorder 
                ? Border.all(color: Colors.black.withOpacity(0.05), width: 1)
                : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
