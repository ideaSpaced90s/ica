import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingBubblesOverlay extends StatefulWidget {
  const FloatingBubblesOverlay({super.key});

  @override
  State<FloatingBubblesOverlay> createState() => _FloatingBubblesOverlayState();
}

class _FloatingBubblesOverlayState extends State<FloatingBubblesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(15, (_) => _Bubble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblePainter(_bubbles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Bubble {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 15 + 5;
  double speed = math.Random().nextDouble() * 0.05 + 0.02;
  double drift = math.Random().nextDouble() * 0.1 - 0.05;
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double animationValue;

  _BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var b in bubbles) {
      final dx = size.width * ((b.x + animationValue * b.drift) % 1.0);
      final dy = size.height * ((b.y - animationValue * b.speed) % 1.0);
      
      paint.color = Colors.white.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(dx, dy), b.size, paint);
      
      // Highlight on bubble
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx - b.size * 0.3, dy - b.size * 0.3), b.size * 0.2, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}

class ToyConfettiSystem extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const ToyConfettiSystem({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<ToyConfettiSystem> createState() => _ToyConfettiSystemState();
}

class _ToyConfettiSystemState extends State<ToyConfettiSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<_ConfettiPart> _parts;

  @override
  void initState() {
    super.initState();
    _parts = List.generate(20, (_) => _ConfettiPart());
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(_parts, _controller.value, widget.position),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiPart {
  Color color = [Colors.red, Colors.blue, Colors.yellow, Colors.green, Colors.orange][math.Random().nextInt(5)];
  double angle = math.Random().nextDouble() * math.pi * 2;
  double distance = math.Random().nextDouble() * 100 + 50;
  double size = math.Random().nextDouble() * 8 + 4;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPart> parts;
  final double progress;
  final Offset center;

  _ConfettiPainter(this.parts, this.progress, this.center);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    for (var p in parts) {
      final t = Curves.easeOutBack.transform(progress);
      final dx = center.dx + math.cos(p.angle) * p.distance * t;
      final dy = center.dy + math.sin(p.angle) * p.distance * t + (progress * 100); // Simulate gravity
      
      final paint = Paint()
        ..color = p.color.withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(Rect.fromCenter(center: Offset(dx, dy), width: p.size, height: p.size), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

class WiggleAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  const WiggleAnimation({super.key, required this.child, required this.isActive});

  @override
  State<WiggleAnimation> createState() => _WiggleAnimationState();
}

class _WiggleAnimationState extends State<WiggleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
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
        return Transform.rotate(
          angle: (math.sin(_controller.value * math.pi * 2) * 0.1),
          child: Transform.scale(
            scale: 1.1 + (math.sin(_controller.value * math.pi * 2) * 0.05),
            child: widget.child,
          ),
        );
      },
    );
  }
}

