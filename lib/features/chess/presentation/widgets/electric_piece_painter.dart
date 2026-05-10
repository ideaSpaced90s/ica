import 'dart:math';
import 'package:flutter/material.dart';

class EnergyPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue;

  EnergyPiecePainter({
    required this.type,
    required this.isWhite,
    required this.isHighlighted,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = isWhite ? const Color(0xFF00BFFF) : const Color(0xFFFF4500); // Electric Blue vs Neon Red
    
    // 1. Piece Silhouette (Mask)
    final charMap = {
      'K': '\u2654', 'Q': '\u2655', 'B': '\u2657', 'N': '\u2658', 'R': '\u2656', 'P': '\u2659'
    };
    final char = charMap[type] ?? '?';

    final textPainter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.9,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;

    // Save Layer for masking
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Paint the shape
    textPainter.paint(canvas, Offset(x, y));

    // Glow and current effect
    final paint = Paint()
      ..blendMode = BlendMode.srcIn
      ..style = PaintingStyle.fill;

    // Background energy fill
    paint.color = color.withValues(alpha: 0.1);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Current lines (jagged electric arcs inside)
    final arcPaint = Paint()
      ..blendMode = BlendMode.srcIn
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final random = Random(type.codeUnitAt(0) + (isWhite ? 1 : 0));
    for (int i = 0; i < 3; i++) {
        final startY = random.nextDouble() * size.height;
        final endY = random.nextDouble() * size.height;
        final path = Path()..moveTo(0, startY);
        
        final segments = 4;
        for (int j = 1; j <= segments; j++) {
            final t = j/segments;
            final jitter = (random.nextDouble() - 0.5) * 15 * sin(animationValue * 5 * pi);
            path.lineTo(size.width * t, Offset.lerp(Offset(0, startY), Offset(size.width, endY), t)!.dy + jitter);
        }
        canvas.drawPath(path, arcPaint);
    }

    // Flicker
    if (sin(animationValue * 20 * pi) > 0.8) {
      paint.color = color.withValues(alpha: 0.05);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    canvas.restore();

    // We can't easily get the path from TextPainter, but we can draw a glow
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);
      canvas.drawCircle(Offset(size.width/2, size.height/2), size.width*0.4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(EnergyPiecePainter oldDelegate) => true;
}
