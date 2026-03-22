import 'package:flutter/material.dart';

/// A reusable widget that prevents horizontal overflow by wrapping children
/// to the next line when space is insufficient.
/// 
/// It acts like a [Row] but with automatic wrapping capabilities.
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;
  final WrapAlignment runAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.center,
    this.runAlignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      runAlignment: runAlignment,
      children: children,
    );
  }
}
