import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Arcade-style blue particle burst shown on piece capture.
///
/// Self-removes from the overlay after the animation completes.
/// Triggered via [ArcadeCaptureBurst.show].
class ArcadeCaptureBurst extends StatefulWidget {
  final Offset center;
  final double squareSize;
  final VoidCallback onComplete;
  final bool reduced;

  const ArcadeCaptureBurst({
    super.key,
    required this.center,
    required this.squareSize,
    required this.onComplete,
    this.reduced = false,
  });

  /// Inserts a self-removing overlay entry for the burst.
  ///
  /// [globalCenter] — center of the target square in global (overlay) coords.
  /// [squareSize]   — size of one board square in logical pixels.
  static void show({
    required OverlayState overlay,
    required Offset globalCenter,
    required double squareSize,
    bool reduced = false,
  }) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: globalCenter.dx - squareSize,
        top: globalCenter.dy - squareSize,
        width: squareSize * 2,
        height: squareSize * 2,
        child: ArcadeCaptureBurst(
          center: Offset(squareSize, squareSize),
          squareSize: squareSize,
          reduced: reduced,
          onComplete: () {
            if (entry.mounted) entry.remove();
          },
        ),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ArcadeCaptureBurst> createState() => _ArcadeCaptureBurstState();
}

class _ArcadeCaptureBurstState extends State<ArcadeCaptureBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_BurstParticle> _particles;
  final _random = math.Random();

  // Blue palette for arcade feel
  static const _colors = [
    Color(0xFF3B82F6), // blue-500
    Color(0xFF60A5FA), // blue-400
    Color(0xFF93C5FD), // blue-300
    Color(0xFFBAE6FD), // sky-200
    Color(0xFFFFFFFF), // white sparks
    Color(0xFF7C3AED), // violet for depth
    Color(0xFF38BDF8), // sky-400
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    // Generate particles in two "shells": inner fast, outer slow.
    // If reduced mode is active, generate 6 particles instead of 16.
    final count = widget.reduced ? 6 : 16;
    _particles = [];
    for (int i = 0; i < count; i++) {
      final angle = (i / count.toDouble()) * 2 * math.pi + (_random.nextDouble() * 0.3);
      final isInner = widget.reduced ? i < 3 : i < 8;
      final speed = isInner
          ? 1.6 + _random.nextDouble() * 1.2
          : 2.8 + _random.nextDouble() * 1.8;
      final size = isInner
          ? 3.5 + _random.nextDouble() * 3.5
          : 2.0 + _random.nextDouble() * 2.5;
      final color = _colors[_random.nextInt(_colors.length)];
      _particles.add(_BurstParticle(
        angle: angle,
        speed: speed,
        size: size,
        color: color,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        isSquare: _random.nextBool(),
      ));
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Ease-out: particles slow toward end
          final eased = Curves.easeOut.transform(t);

          return Stack(
            children: [
              // Shockwave ring
              _buildShockwaveRing(t),
              // Center flash
              _buildCenterFlash(t),
              // Particles
              ..._particles.map((p) => _buildParticle(p, eased, t)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShockwaveRing(double t) {
    final radius = widget.squareSize * 0.25 +
        widget.squareSize * 0.85 * Curves.easeOut.transform(t);
    final opacity = (1.0 - t) * 0.7;
    return Positioned(
      left: widget.center.dx - radius,
      top: widget.center.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF60A5FA),
              width: 2.0 * (1.0 - t * 0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFlash(double t) {
    // Flash peaks at 10% then fades quickly
    final flashT = (t * 10).clamp(0.0, 1.0);
    final opacity = (1.0 - flashT) * 0.9;
    final radius = widget.squareSize * 0.18 * flashT;
    return Positioned(
      left: widget.center.dx - radius,
      top: widget.center.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Colors.white, Color(0xFF60A5FA)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(_BurstParticle p, double eased, double t) {
    final distance = p.speed * eased * widget.squareSize * 0.65;
    final x = widget.center.dx + math.cos(p.angle) * distance;
    final y = widget.center.dy + math.sin(p.angle) * distance;
    // Fade: particles visible from 0→0.75 of lifetime
    final opacity = t < 0.75
        ? (1.0 - (t / 0.75) * 0.3)
        : (1.0 - 0.3 - ((t - 0.75) / 0.25) * 0.7);
    final rotation = p.rotationSpeed * t;

    final halfSize = p.size / 2;
    return Positioned(
      left: x - halfSize,
      top: y - halfSize,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rotation,
          child: Container(
            width: p.size,
            height: p.size,
            decoration: BoxDecoration(
              color: p.color,
              borderRadius: p.isSquare
                  ? BorderRadius.circular(1)
                  : BorderRadius.circular(p.size),
              boxShadow: [
                BoxShadow(
                  color: p.color.withValues(alpha: 0.6),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double rotationSpeed;
  final bool isSquare;

  const _BurstParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.isSquare,
  });
}
