import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A continuous random shake animation used to indicate tension or threat.
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final double intensity;

  const ShakeAnimation({
    super.key,
    required this.child,
    required this.isActive,
    this.intensity = 3.0,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Random displacement on every build for a nervous effect
        final random = math.Random();
        final dx = (random.nextDouble() * 2 - 1) * widget.intensity;
        final dy = (random.nextDouble() * 2 - 1) * (widget.intensity * 0.5); // Less vertical shake
        
        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
