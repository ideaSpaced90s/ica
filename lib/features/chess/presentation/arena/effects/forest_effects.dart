import 'dart:math' as math;
import 'package:flutter/material.dart';

class ForestDustOverlay extends StatefulWidget {
  const ForestDustOverlay({super.key});

  @override
  State<ForestDustOverlay> createState() => _ForestDustOverlayState();
}

class _ForestDustOverlayState extends State<ForestDustOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_DustParticle> _particles = List.generate(
    25,
    (_) => _DustParticle(),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
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
          painter: _DustPainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _DustParticle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 2 + 1;
  double speed = math.Random().nextDouble() * 0.02 + 0.005;
  double opacity = math.Random().nextDouble() * 0.3 + 0.1;
}

class _DustPainter extends CustomPainter {
  final List<_DustParticle> particles;
  final double animationValue;

  _DustPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      // Slow drifting movement
      final dx = size.width * ((p.x + animationValue * p.speed) % 1.0);
      final dy = size.height * ((p.y + animationValue * p.speed * 0.5) % 1.0);

      paint.color = Colors.white.withValues(
        alpha:
            p.opacity *
            (0.5 + 0.5 * math.sin(animationValue * math.pi * 2 + p.x * 10)),
      );
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue ||
      particles != oldDelegate.particles;
}

class LeafScatterEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const LeafScatterEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<LeafScatterEffect> createState() => _LeafScatterEffectState();
}

class _LeafScatterEffectState extends State<LeafScatterEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<_LeafParticle> _leaves;

  @override
  void initState() {
    super.initState();
    _leaves = List.generate(8, (_) => _LeafParticle());
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onComplete();
          }
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
          painter: _LeafPainter(_leaves, _controller.value, widget.position),
          size: Size.infinite,
        );
      },
    );
  }
}

class _LeafParticle {
  double angle = math.Random().nextDouble() * math.pi * 2;
  double distance = math.Random().nextDouble() * 40 + 20;
  double rotation = math.Random().nextDouble() * math.pi * 4;
}

class _LeafPainter extends CustomPainter {
  final List<_LeafParticle> leaves;
  final double progress;
  final Offset center;

  _LeafPainter(this.leaves, this.progress, this.center);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final paint = Paint()
      ..color = const Color(
        0xFF4F7942,
      ).withValues(alpha: 0.8 * (1.0 - progress))
      ..style = PaintingStyle.fill;

    for (var leaf in leaves) {
      final t = Curves.easeOutCubic.transform(progress);
      final currentDist = leaf.distance * t;
      final dx = center.dx + math.cos(leaf.angle) * currentDist;
      final dy = center.dy + math.sin(leaf.angle) * currentDist;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(leaf.rotation * progress);

      // Simple leaf shape
      final path = Path()
        ..moveTo(0, -6)
        ..quadraticBezierTo(4, 0, 0, 6)
        ..quadraticBezierTo(-4, 0, 0, -6)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      center != oldDelegate.center ||
      leaves != oldDelegate.leaves;
}

class SelectionGlowRing extends StatefulWidget {
  final bool isActive;
  const SelectionGlowRing({super.key, required this.isActive});

  @override
  State<SelectionGlowRing> createState() => _SelectionGlowRingState();
}

class _SelectionGlowRingState extends State<SelectionGlowRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return CustomPaint(
            painter: _RingPainter(progress),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width * 0.45;
    final currentRadius = maxRadius * (0.4 + 0.6 * progress);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = const Color(0xFFE6D3A3).withValues(alpha: opacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, currentRadius, paint);

    final glowPaint = Paint()
      ..color = const Color(0xFFE6D3A3).withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(center, currentRadius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class LeafTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Deterministic randomness
    for (int i = 0; i < 3; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final rotation = random.nextDouble() * math.pi * 2;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);

      final path = Path()
        ..moveTo(0, -4)
        ..quadraticBezierTo(3, 0, 0, 4)
        ..quadraticBezierTo(-3, 0, 0, -4)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LeafTexturePainter oldDelegate) => false;
}
