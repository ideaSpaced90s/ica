import 'dart:math' as math;
import 'package:flutter/material.dart';

class BishopWindEffect extends StatefulWidget {
  final Offset from;
  final Offset to;
  final double squareSize;
  final VoidCallback onComplete;

  const BishopWindEffect({
    super.key,
    required this.from,
    required this.to,
    required this.squareSize,
    required this.onComplete,
  });

  @override
  State<BishopWindEffect> createState() => _BishopWindEffectState();
}

class _BishopWindEffectState extends State<BishopWindEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_WindStreak> _streaks = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Create parallel streaks along the path
    final direction = widget.to - widget.from;
    final length = direction.distance;
    final normalizedDir = direction / length;
    final perpendicular = Offset(-normalizedDir.dy, normalizedDir.dx);

    for (int i = 0; i < 8; i++) {
      final sideOffset = (i - 3.5) * widget.squareSize * 0.15;
      final startT = _random.nextDouble() * 0.3;
      final speed = 0.7 + _random.nextDouble() * 0.5;
      
      _streaks.add(_WindStreak(
        sideOffset: perpendicular * sideOffset,
        startT: startT,
        speed: speed,
        width: 20.0 + _random.nextDouble() * 40.0,
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
    final direction = widget.to - widget.from;
    final angle = math.atan2(direction.dy, direction.dx);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final globalProgress = _controller.value;

        return Stack(
          children: _streaks.map((s) {
            // Calculate local progress for this streak
            final localProgress = ((globalProgress - s.startT) * s.speed).clamp(0.0, 1.0);
            if (localProgress <= 0 || localProgress >= 1.0) return const SizedBox.shrink();

            final pos = Offset.lerp(widget.from, widget.to, localProgress)! + s.sideOffset;
            final opacity = (math.sin(localProgress * math.pi) * 0.3).clamp(0.0, 1.0);

            return Positioned(
              left: pos.dx - s.width / 2,
              top: pos.dy - 1,
              child: Transform.rotate(
                angle: angle,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: s.width,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.0),
                        ],
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

class _WindStreak {
  final Offset sideOffset;
  final double startT;
  final double speed;
  final double width;

  _WindStreak({
    required this.sideOffset,
    required this.startT,
    required this.speed,
    required this.width,
  });
}
