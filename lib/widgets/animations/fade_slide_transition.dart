import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Offset begin;

  const FadeSlideTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.begin = const Offset(0, 30),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: 600.ms, curve: Curves.easeOutCubic)
        .slide(begin: begin, end: Offset.zero, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}
