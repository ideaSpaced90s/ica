import 'dart:math' as math;
import 'package:flutter/material.dart';

class SteampunkPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;
  final double rotation; // Animation value for gears (0.0 to 1.0)

  SteampunkPiecePainter({
    required this.type,
    required this.isWhite,
    required this.rotation,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2.3;

    // 1. Metal Gradient (Industrial & Textured)
    final metalGradient = LinearGradient(
      colors: isWhite
          ? [
              const Color(0xFFFFD700), // Gold/Brass
              const Color(0xFFB8860B),
            ]
          : [
              const Color(0xFF757575), // Iron/Steel
              const Color(0xFF212121),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = metalGradient
      ..style = PaintingStyle.fill;

    // 2. Mechanical Shading
    final shadingPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Path path = _getSteampunkPath(type, center, radius);

    // Draw Base Metal
    canvas.drawPath(path, paint);
    canvas.drawPath(path, shadingPaint);

    // 3. Rotating Gears (Inside the pieces)
    _drawRotatingGears(canvas, center, radius);
    
    // 4. Highlight & Bolts
    _drawMechanicalDetails(canvas, center, radius);
  }

  void _drawRotatingGears(Canvas canvas, Offset center, double radius) {
    final gearPaint = Paint()
      ..color = isWhite ? const Color(0xFFDAA520) : const Color(0xFF424242)
      ..style = PaintingStyle.fill;

    final gearStroke = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi); // Full rotation based on animation

    // Draw a small gear with teeth
    const int teethCount = 8;
    final gearRadius = radius * 0.3;
    final Path gearPath = Path();
    
    for (int i = 0; i < teethCount * 2; i++) {
        final r = (i % 2 == 0) ? gearRadius : gearRadius * 1.2;
        final angle = (i / (teethCount * 2)) * 2 * math.pi;
        if (i == 0) {
            gearPath.moveTo(math.cos(angle) * r, math.sin(angle) * r);
        } else {
            gearPath.lineTo(math.cos(angle) * r, math.sin(angle) * r);
        }
    }
    gearPath.close();
    
    canvas.drawPath(gearPath, gearPaint);
    canvas.drawPath(gearPath, gearStroke);
    
    // Inner center hole
    canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.black.withValues(alpha: 0.4));
    
    canvas.restore();
  }

  void _drawMechanicalDetails(Canvas canvas, Offset center, double radius) {
     final boltPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
     // Bolts at piece corners/points
     canvas.drawCircle(center + Offset(-radius * 0.4, radius * 0.7), 2, boltPaint);
     canvas.drawCircle(center + Offset(radius * 0.4, radius * 0.7), 2, boltPaint);
  }

  Path _getSteampunkPath(String type, Offset center, double radius) {
    switch (type) {
      case 'K': return _mechanicalKingPath(center, radius);
      case 'Q': return _mechanicalQueenPath(center, radius);
      case 'B': return _mechanicalBishopPath(center, radius);
      case 'N': return _mechanicalKnightPath(center, radius);
      case 'R': return _mechanicalRookPath(center, radius);
      default: return _mechanicalPawnPath(center, radius);
    }
  }

  Path _mechanicalKingPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.4)
      ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.4)
      ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.4)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.4)
      ..close();
  }

  Path _mechanicalQueenPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.7)
      ..lineTo(center.dx, center.dy - radius * 0.4)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.7)
      ..close();
  }

  Path _mechanicalBishopPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx, center.dy - radius * 0.8)
      ..close();
  }

  Path _mechanicalKnightPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy)
      ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.6)
      ..close();
  }

  Path _mechanicalRookPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx - radius * 0.5, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.5, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.6)
      ..lineTo(center.dx - radius * 0.3, center.dy - radius * 0.6)
      ..lineTo(center.dx - radius * 0.3, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.8)
      ..close();
  }

  Path _mechanicalPawnPath(Offset center, double radius) {
    return Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.2, center.dy)
      ..addOval(Rect.fromCircle(center: center + Offset(0, -radius * 0.3), radius: radius * 0.4));
  }

  @override
  bool shouldRepaint(covariant SteampunkPiecePainter oldDelegate) => true;
}
