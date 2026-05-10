import 'package:flutter/material.dart';
import 'dart:math' as math;

class BlockShatterEffect extends StatefulWidget {
  final Offset position;
  final bool isWhite;
  final VoidCallback onComplete;

  const BlockShatterEffect({
    super.key,
    required this.position,
    required this.isWhite,
    required this.onComplete,
  });

  @override
  State<BlockShatterEffect> createState() => _BlockShatterEffectState();
}

class _BlockShatterEffectState extends State<BlockShatterEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BlockParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Create 12-16 block particles
    final color = widget.isWhite ? const Color(0xFFF5F5F5) : const Color(0xFFD32F2F);
    
    for (int i = 0; i < 15; i++) {
      _particles.add(_BlockParticle(
        angle: _random.nextDouble() * 2 * math.pi,
        velocity: 2.0 + _random.nextDouble() * 5.0,
        size: 6.0 + _random.nextDouble() * 8.0,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        color: color,
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
        return Stack(
          children: _particles.map((p) {
            final progress = _controller.value;
            final x = widget.position.dx + math.cos(p.angle) * p.velocity * progress * 80;
            final y = widget.position.dy + math.sin(p.angle) * p.velocity * progress * 80 + (progress * progress * 150);
            final rotation = progress * p.rotationSpeed * 50;
            final opacity = (1.0 - progress).clamp(0.0, 1.0);

            return Positioned(
              left: x - p.size / 2,
              top: y - p.size / 2,
              child: Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      color: p.color,
                      border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(1, 1)),
                      ],
                    ),
                    // Add a tiny circle to look like a stud
                    child: Center(
                      child: Container(
                        width: p.size * 0.4,
                        height: p.size * 0.4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BlockParticle {
  final double angle;
  final double velocity;
  final double size;
  final double rotationSpeed;
  final Color color;

  _BlockParticle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });
}
