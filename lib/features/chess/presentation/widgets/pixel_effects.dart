import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'pixel_theme_hd.dart';

class PixelDisintegration extends StatefulWidget {
  final Offset position;
  final bool isWhite;
  final VoidCallback onComplete;

  const PixelDisintegration({
    super.key,
    required this.position,
    required this.isWhite,
    required this.onComplete,
  });

  @override
  State<PixelDisintegration> createState() => _PixelDisintegrationState();
}

class _PixelDisintegrationState extends State<PixelDisintegration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_PixelParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    // Initialize 24-32 particles in a rough piece shape
    for (int i = 0; i < 24; i++) {
      _particles.add(_PixelParticle(
        x: (_random.nextDouble() - 0.5) * 40,
        y: (_random.nextDouble() - 0.5) * 60,
        vx: (_random.nextDouble() - 0.5) * 150,
        vy: (_random.nextDouble() - 1.0) * 200, // Blow upwards
        size: 3.0 + _random.nextDouble() * 4.0,
      ));
    }

    _controller.forward().then((_) => widget.onComplete());
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
        return Positioned(
          left: widget.position.dx,
          top: widget.position.dy,
          child: CustomPaint(
            painter: _PixelParticlePainter(
              particles: _particles,
              progress: _controller.value,
              isWhite: widget.isWhite,
            ),
          ),
        );
      },
    );
  }
}

class _PixelParticle {
  double x, y, vx, vy, size;
  _PixelParticle(
      {required this.x,
      required this.y,
      required this.vx,
      required this.vy,
      required this.size});
}

class _PixelParticlePainter extends CustomPainter {
  final List<_PixelParticle> particles;
  final double progress;
  final bool isWhite;

  _PixelParticlePainter(
      {required this.particles, required this.progress, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isWhite ? PixelColors.whitePiece : PixelColors.blackPiece)
          .withValues(alpha: 1.0 - progress);

    for (var p in particles) {
      final double x = p.x + p.vx * progress;
      final double y = p.y + p.vy * progress + (9.8 * 20 * progress * progress); // Gravity
      
      // Draw as a small square (pixel)
      canvas.drawRect(Rect.fromLTWH(x, y, p.size, p.size), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PixelCheckPulse extends StatefulWidget {
  const PixelCheckPulse({super.key});

  @override
  State<PixelCheckPulse> createState() => _PixelCheckPulseState();
}

class _PixelCheckPulseState extends State<PixelCheckPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..repeat(reverse: true);
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
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.6 * _controller.value),
              width: 4 * (1.0 - _controller.value) + 1, // Flashing border thickness
            ),
          ),
        );
      },
    );
  }
}
