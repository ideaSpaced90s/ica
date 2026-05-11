import 'dart:math' as math;
import 'package:flutter/material.dart';

class KnightDustEffect extends StatefulWidget {
  final Offset position;
  final double squareSize;
  final VoidCallback onComplete;

  const KnightDustEffect({
    super.key,
    required this.position,
    required this.squareSize,
    required this.onComplete,
  });

  @override
  State<KnightDustEffect> createState() => _KnightDustEffectState();
}

class _KnightDustEffectState extends State<KnightDustEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Create particles radiating outwards
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + (_random.nextDouble() * 0.4);
      final speed = 1.5 + _random.nextDouble() * 2.5;
      _particles.add(_Particle(
        angle: angle,
        speed: speed,
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
        final progress = _controller.value;
        return Stack(
          children: _particles.map((p) {
            final distance = p.speed * progress * widget.squareSize * 0.6;
            final x = widget.position.dx + math.cos(p.angle) * distance;
            final y = widget.position.dy + math.sin(p.angle) * distance;
            
            // Fade out and shrink
            final opacity = (1.0 - progress).clamp(0.0, 1.0);
            final scale = 1.0 + progress * 0.5;

            return Positioned(
              left: x - p.size / 2,
              top: y - p.size / 2,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(
                      color: Colors.brown.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 2,
                        ),
                      ],
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

class _Particle {
  final double angle;
  final double speed;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
  });
}
