import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/chess_provider.dart';

class AmbientFlowBackdrop extends ConsumerStatefulWidget {
  final Color blob1Color;
  final Color blob2Color;
  final Color blob3Color;
  final Color backgroundColor;
  final Color? overlayColor;

  const AmbientFlowBackdrop({
    super.key,
    this.blob1Color = const Color(0xFFDBEAFE), // Default: soft blue
    this.blob2Color = const Color(0xFFFEF3C7), // Default: soft amber
    this.blob3Color = const Color(0xFFF3E8FF), // Default: soft purple
    this.backgroundColor = const Color(0xFFF8F9FA),
    this.overlayColor,
  });

  @override
  ConsumerState<AmbientFlowBackdrop> createState() =>
      _AmbientFlowBackdropState();
}

class _AmbientFlowBackdropState extends ConsumerState<AmbientFlowBackdrop>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  /// Slow shimmer controller for arcade mode (30s full cycle)
  late AnimationController _arcadeShimmer;

  @override
  void initState() {
    super.initState();
    // Use different durations to avoid synchronized repetition
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    _controller3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // Arcade shimmer: very slow, diagonal drift
    _arcadeShimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _arcadeShimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final arcadeMode = ref
        .watch(chessProvider.select(
          (s) => s.animationSettings['arcadeMode'] ?? false,
        ));

    return Stack(
      children: [
        // Base background color matching scholarly theme backgroundStart
        Container(
          color: widget.backgroundColor,
        ),
        // Blob 1: Soft Indigo/Blue
        AnimatedBuilder(
          animation: _controller1,
          builder: (context, child) {
            final angle = _controller1.value * 2 * pi;
            // Orbit around center-left
            final dx = size.width * 0.2 + cos(angle) * 80;
            final dy = size.height * 0.3 + sin(angle) * 120;
            return Positioned(
              left: dx - 180,
              top: dy - 180,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.blob1Color,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Blob 2: Soft Amber/Yellow
        AnimatedBuilder(
          animation: _controller2,
          builder: (context, child) {
            final angle = _controller2.value * 2 * pi;
            // Orbit around center-right
            final dx = size.width * 0.8 + sin(angle) * 100;
            final dy = size.height * 0.6 + cos(angle) * 140;
            return Positioned(
              left: dx - 200,
              top: dy - 200,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.blob2Color,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Blob 3: Soft Lavender/Pink
        AnimatedBuilder(
          animation: _controller3,
          builder: (context, child) {
            final angle = _controller3.value * 2 * pi;
            // Orbit around center-bottom
            final dx = size.width * 0.4 + cos(angle) * 120;
            final dy = size.height * 0.85 + sin(angle) * 70;
            return Positioned(
              left: dx - 160,
              top: dy - 160,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.blob3Color,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        // Blur Filter to merge them into a smooth liquid gradient
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(
              color: widget.overlayColor ?? Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        // ── Arcade Mode: slow-drifting shimmer orbs ──────────────────────
        if (arcadeMode)
          AnimatedBuilder(
            animation: _arcadeShimmer,
            builder: (context, _) {
              return CustomPaint(
                size: size,
                painter: _ArcadeShimmerPainter(_arcadeShimmer.value),
              );
            },
          ),
      ],
    );
  }
}

/// Paints 7 large soft radial gradient orbs that drift diagonally
/// at a very slow pace to give a "living world" arcade background feel.
/// Alpha is kept very low (0.03–0.07) so it is never distracting.
class _ArcadeShimmerPainter extends CustomPainter {
  final double t; // 0.0 → 1.0, repeating
  _ArcadeShimmerPainter(this.t);

  static const _orbs = [
    // [relX, relY, radius, hue(°), alpha]
    [0.15, 0.20, 220.0, 210.0, 0.060], // top-left blue
    [0.80, 0.15, 180.0, 260.0, 0.045], // top-right violet
    [0.50, 0.50, 280.0, 220.0, 0.035], // centre sky
    [0.10, 0.75, 200.0, 190.0, 0.050], // bottom-left teal
    [0.85, 0.70, 240.0, 230.0, 0.040], // bottom-right indigo
    [0.35, 0.10, 160.0, 240.0, 0.055], // top-centre blue
    [0.65, 0.85, 200.0, 200.0, 0.042], // bottom-centre sky
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _orbs.length; i++) {
      final orb = _orbs[i];
      final phase = (t + i * 0.143) % 1.0; // stagger each orb
      // Slow diagonal drift: ±4% of screen dimensions
      final driftX = sin(phase * 2 * pi) * size.width * 0.04;
      final driftY = cos(phase * 2 * pi + 1.0) * size.height * 0.04;

      final cx = orb[0] * size.width + driftX;
      final cy = orb[1] * size.height + driftY;
      final radius = orb[2].toDouble();
      final hue = orb[3].toDouble();
      final alpha = orb[4].toDouble();

      final color = HSVColor.fromAHSV(1.0, hue, 0.55, 0.92).toColor();
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcadeShimmerPainter old) => old.t != t;
}
