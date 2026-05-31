import 'dart:math';
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
  late AnimationController _waveController;

  /// Slow shimmer controller for arcade mode (30s full cycle)
  late AnimationController _arcadeShimmer;

  @override
  void initState() {
    super.initState();
    // Very slow wave duration for a subtle shifting effect
    _waveController = AnimationController(
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
    _waveController.dispose();
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
        // Base background color
        Container(
          color: widget.backgroundColor,
        ),
        // Flowing shadow waves on top
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: AmbientWavePainter(
                  _waveController.value,
                  widget.blob1Color,
                  widget.blob2Color,
                  widget.blob3Color,
                ),
              );
            },
          ),
        ),
        // Optional overlay color if specified
        if (widget.overlayColor != null)
          Positioned.fill(
            child: Container(
              color: widget.overlayColor,
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

class AmbientWavePainter extends CustomPainter {
  final double t;
  final Color color1;
  final Color color2;
  final Color color3;

  AmbientWavePainter(this.t, this.color1, this.color2, this.color3);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Wave 1: Soft Back Layer (using color2 - default warm amber)
    final paint1 = Paint()
      ..shader = LinearGradient(
        colors: [
          color2.withValues(alpha: 0.0),
          color2.withValues(alpha: 0.08),
          color2.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path1 = Path();
    path1.moveTo(0, h * 0.4);
    for (double x = 0; x <= w; x++) {
      final y = h * 0.4 +
          sin((x / w * 2 * pi) + (t * 2 * pi)) * 30 +
          cos((x / w * pi) - (t * pi)) * 12;
      path1.lineTo(x, y);
    }
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Wave 2: Soft Middle Layer (using color1 - default soft blue)
    final paint2 = Paint()
      ..shader = LinearGradient(
        colors: [
          color1.withValues(alpha: 0.0),
          color1.withValues(alpha: 0.18),
          color1.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path();
    path2.moveTo(0, h * 0.6);
    for (double x = 0; x <= w; x++) {
      final y = h * 0.6 +
          cos((x / w * 2 * pi) - (t * 2 * pi * 1.1)) * 35 +
          sin((x / w * 1.5 * pi) + (t * pi)) * 18;
      path2.lineTo(x, y);
    }
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Wave 3: Soft Front Layer (using color3 - default soft purple)
    final paint3 = Paint()
      ..shader = LinearGradient(
        colors: [
          color3.withValues(alpha: 0.0),
          color3.withValues(alpha: 0.06),
          color3.withValues(alpha: 0.0),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path3 = Path();
    path3.moveTo(0, h * 0.78);
    for (double x = 0; x <= w; x++) {
      final y = h * 0.78 +
          sin((x / w * 2 * pi) + (t * 2 * pi * 0.9) + 1.2) * 25 +
          cos((x / w * pi) + (t * 2 * pi)) * 15;
      path3.lineTo(x, y);
    }
    path3.lineTo(w, h);
    path3.lineTo(0, h);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant AmbientWavePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2 ||
        oldDelegate.color3 != color3;
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
