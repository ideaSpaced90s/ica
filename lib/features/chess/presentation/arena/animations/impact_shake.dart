import 'package:flutter/material.dart';

class ImpactShake extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Offset direction;
  final double intensity;
  final VoidCallback? onComplete;

  const ImpactShake({
    super.key,
    required this.child,
    this.trigger = false,
    this.direction = Offset.zero,
    this.intensity = 5.0,
    this.onComplete,
  });

  @override
  State<ImpactShake> createState() => _ImpactShakeState();
}

class _ImpactShakeState extends State<ImpactShake>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: -0.6,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.6,
          end: 0.3,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: -0.1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.1,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    if (widget.trigger) {
      _controller.forward().then((_) => widget.onComplete?.call());
    }
  }

  @override
  void didUpdateWidget(ImpactShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.reset();
      _controller.forward().then((_) => widget.onComplete?.call());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = widget.direction * _animation.value * widget.intensity;
        return Transform.translate(offset: offset, child: child);
      },
      child: widget.child,
    );
  }
}
