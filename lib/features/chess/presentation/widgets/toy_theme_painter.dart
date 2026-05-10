import 'package:flutter/material.dart';

class ToyPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;

  ToyPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2.3;

    // 1. Plastic Base Gradient (Chunky & Soft)
    final plasticGradient = LinearGradient(
      colors: isWhite
          ? [
              const Color(0xFFBBDEFB), // Pastel Blue
              const Color(0xFF64B5F6),
            ]
          : [
              const Color(0xFFE1BEE7), // Playful Purple
              const Color(0xFFBA68C8),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = plasticGradient
      ..style = PaintingStyle.fill;

    // 2. Toy Highlight (Soft reflection)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final Path path = _getToyPath(type, center, radius);

    // Draw Base
    canvas.drawPath(path, paint);
    
    // Draw Soft Highlight
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(center - Offset(radius * 0.3, radius * 0.3), radius * 0.4, highlightPaint);
    canvas.restore();

    // 3. Subtle Stroke
    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);
    
    // 4. Dot Eyes for Pawns (Subtle)
    if (type == 'P') {
      final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.6);
      canvas.drawCircle(center + Offset(-radius * 0.15, -radius * 0.15), 2, eyePaint);
      canvas.drawCircle(center + Offset(radius * 0.15, -radius * 0.15), 2, eyePaint);
    }
  }

  Path _getToyPath(String type, Offset center, double radius) {
    switch (type) {
      case 'K': return _toyKingPath(center, radius);
      case 'Q': return _toyQueenPath(center, radius);
      case 'B': return _toyBishopPath(center, radius);
      case 'N': return _toyKnightPath(center, radius);
      case 'R': return _toyRookPath(center, radius);
      default: return _toyPawnPath(center, radius);
    }
  }

  Path _toyKingPath(Offset center, double radius) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + Offset(0, radius * 0.4), width: radius * 1.2, height: radius * 0.8),
          const Radius.circular(12)))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center - Offset(0, radius * 0.1), width: radius * 0.8, height: radius * 1.0),
          const Radius.circular(12)))
      ..addOval(Rect.fromCircle(center: center - Offset(0, radius * 0.6), radius: radius * 0.3));
  }

  Path _toyQueenPath(Offset center, double radius) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + Offset(0, radius * 0.4), width: radius * 1.1, height: radius * 0.8),
          const Radius.circular(12)))
      ..addOval(Rect.fromCircle(center: center - Offset(0, radius * 0.2), radius: radius * 0.45));
  }

  Path _toyBishopPath(Offset center, double radius) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + Offset(0, radius * 0.5), width: radius * 0.9, height: radius * 0.6),
          const Radius.circular(10)))
      ..addOval(Rect.fromCircle(center: center - Offset(0, radius * 0.1), radius: radius * 0.45));
  }

  Path _toyKnightPath(Offset center, double radius) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + Offset(0, radius * 0.5), width: radius * 1.0, height: radius * 0.5),
          const Radius.circular(10)))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center - Offset(radius * 0.1, 0), width: radius * 0.6, height: radius * 1.0),
          const Radius.circular(12)))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center - Offset(radius * 0.4, radius * 0.3), width: radius * 0.4, height: radius * 0.3),
          const Radius.circular(4)));
  }

  Path _toyRookPath(Offset center, double radius) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center + Offset(0, radius * 0.2), width: radius * 1.0, height: radius * 1.2),
          const Radius.circular(8)))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: center - Offset(0, radius * 0.5), width: radius * 1.2, height: radius * 0.3),
          const Radius.circular(4)));
  }

  Path _toyPawnPath(Offset center, double radius) {
    return Path()
      ..addOval(Rect.fromCircle(center: center + Offset(0, radius * 0.3), radius: radius * 0.5))
      ..addOval(Rect.fromCircle(center: center - Offset(0, radius * 0.25), radius: radius * 0.4));
  }

  @override
  bool shouldRepaint(covariant ToyPiecePainter oldDelegate) => true;
}
