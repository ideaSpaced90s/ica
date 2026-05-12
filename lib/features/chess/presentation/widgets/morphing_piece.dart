import 'dart:math';
import 'package:flutter/material.dart';

class MorphingPiece extends StatefulWidget {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;

  const MorphingPiece({
    super.key,
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  State<MorphingPiece> createState() => _MorphingPieceState();
}

class _MorphingPieceState extends State<MorphingPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _morphController;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphController,
      builder: (context, child) {
        return CustomPaint(
          painter: LiquidPiecePainter(
            type: widget.type,
            isWhite: widget.isWhite,
            isHighlighted: widget.isHighlighted,
            animationValue: _morphController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class LiquidPiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue;

  LiquidPiecePainter({
    required this.type,
    required this.isWhite,
    required this.isHighlighted,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2.2;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Fluid Path Calculation
    final path = _getFluidPath(center, radius, animationValue);

    // 2. Base Fill with Inner Shimmer
    final fillPaint = Paint()
      ..shader = isWhite
          ? const RadialGradient(
              colors: [Color(0xFFE0F7FA), Color(0xFF4DD0E1), Color(0xFF00ACC1)],
              stops: [0.3, 0.7, 1.0],
            ).createShader(rect)
          : const RadialGradient(
              colors: [Color(0xFF37474F), Color(0xFF263238), Color(0xFF000000)],
              stops: [0.0, 0.6, 1.0],
            ).createShader(rect)
      ..style = PaintingStyle.fill;

    // 3. Ambient Shimmer (animated highlights)
    final shimmerPaint = Paint()
      ..color = Colors.white.withValues(alpha: isWhite ? 0.3 : 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..style = PaintingStyle.fill;

    // 4. Highlight Paint for wave distortion when selected
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = isWhite ? const Color(0xFF80DEEA) : const Color(0xFF4DB6AC)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, glowPaint);
    }

    canvas.drawPath(path, fillPaint);

    // Draw tiny shimmering bubbles inside "White" (Water) pieces
    if (isWhite) {
      for (var i = 0; i < 4; i++) {
        final bubbleOffset = Offset(
          center.dx + radius * 0.3 * cos(animationValue * 2 * pi + i),
          center.dy + radius * 0.3 * sin(animationValue * 2 * pi + i + pi / 4),
        );
        canvas.drawCircle(bubbleOffset, 3, shimmerPaint);
      }
    } else {
      // Ink pieces have a "thick" highlight on one edge
      final inkHighlightPath = Path()
        ..moveTo(center.dx - radius * 0.2, center.dy - radius * 0.4)
        ..quadraticBezierTo(
          center.dx + radius * 0.4,
          center.dy - radius * 0.5,
          center.dx + radius * 0.3,
          center.dy + radius * 0.2,
        );
      canvas.drawPath(
        inkHighlightPath,
        shimmerPaint
          ..strokeWidth = 4.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  Path _getFluidPath(Offset center, double r, double anim) {
    switch (type.toUpperCase()) {
      case 'K':
        return _drawBlobby(center, r, 7, anim); // More complex blob
      case 'Q':
        return _drawBlobby(center, r, 9, anim);
      case 'B':
        return _drawBlobby(center, r, 4, anim); // Simpler/Smoother
      case 'N':
        return _drawBlobby(center, r, 6, anim, asymmetrical: true);
      case 'R':
        return _drawBlobby(center, r, 5, anim);
      default:
        return _drawBlobby(center, r, 3, anim); // Minimal pawn blob
    }
  }

  // Organic blob generator that retains basic chess silhouette proportions
  Path _drawBlobby(
    Offset c,
    double r,
    int vertexCount,
    double anim, {
    bool asymmetrical = false,
  }) {
    final path = Path();
    final points = <Offset>[];

    for (var i = 0; i < vertexCount; i++) {
      final angle = i * 2 * pi / vertexCount;
      final morph = 0.05 * sin(anim * 2 * pi + i);
      final dist = asymmetrical && i % 2 == 0 ? r * 0.8 : r;
      final offset = Offset(
        c.dx + (dist + morph * r) * cos(angle),
        c.dy + (dist + morph * r) * sin(angle),
      );
      points.add(offset);
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < vertexCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % vertexCount];
      final cp = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);

      // Add more "fluidity" by pulling control points
      final cpFluid = Offset(
        cp.dx + (asin(anim) * 5),
        cp.dy + (acos(anim) * 5),
      );

      path.quadraticBezierTo(p1.dx, p1.dy, cpFluid.dx, cpFluid.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant LiquidPiecePainter oldDelegate) => true;
}
