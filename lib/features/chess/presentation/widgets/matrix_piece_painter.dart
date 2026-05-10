import 'dart:math';
import 'package:flutter/material.dart';

class MatrixPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue; // For idle data streaming

  MatrixPiecePainter({
    required this.type,
    required this.isWhite,
    required this.isHighlighted,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainColor = isWhite ? const Color(0xFF00FF88) : const Color(0xFF006644);
    
    // 1. Draw Piece Silhouette using TextPainter (to get the path/region)
    final charMap = {
      'K': '\u2654', 'Q': '\u2655', 'B': '\u2657', 'N': '\u2658', 'R': '\u2656', 'P': '\u2659'
    };
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: charMap[type] ?? '?',
        style: TextStyle(
          color: Colors.white, // Color doesn't matter for masking
          fontSize: size.width * 0.9,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Centering
    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;

    // Create a Layer for masking
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Paint the piece shape (this will act as the mask)
    textPainter.paint(canvas, Offset(x, y));

    // Change composite mode to srcIn so subsequent drawing only shows up inside the piece shape
    final paint = Paint()
      ..blendMode = BlendMode.srcIn
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw vertical data lines
    final lineCount = 12;
    final spacing = size.width / lineCount;
    final random = Random(type.codeUnitAt(0));

    for (int i = 0; i <= lineCount; i++) {
      final lx = i * spacing;
      final speed = 0.5 + random.nextDouble();
      final phase = (animationValue * speed) % 1.0;
      
      // Draw a line segment that "streams" down
      final startY = phase * size.height;
      final length = 15.0 + random.nextDouble() * 25.0;
      
      paint.color = mainColor.withValues(alpha: 0.8);
      canvas.drawLine(Offset(lx, startY), Offset(lx, startY + length), paint);
      
      // Wrapped part
      if (startY + length > size.height) {
        canvas.drawLine(Offset(lx, startY - size.height), Offset(lx, startY + length - size.height), paint);
      }
      
      // Randomly draw full dim static lines
      if (random.nextDouble() > 0.3) {
        paint.color = mainColor.withValues(alpha: 0.15);
        canvas.drawLine(Offset(lx, 0), Offset(lx, size.height), paint);
      }
    }

    // Flicker effect
    if (Random().nextDouble() > 0.96) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = mainColor.withValues(alpha: 0.05),
      );
    }

    canvas.restore();

    // If highlighted, add a subtle digital glow
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = mainColor.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
       canvas.drawCircle(Offset(size.width/2, size.height/2), size.width*0.4, glowPaint);
    }
  }

  @override
  bool shouldRepaint(MatrixPiecePainter oldDelegate) => true;
}
