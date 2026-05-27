import 'package:flutter/material.dart';

class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.offsetY = 18,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
