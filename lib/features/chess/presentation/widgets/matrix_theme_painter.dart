import 'dart:math';
import 'package:flutter/material.dart';

class MatrixSquarePainter extends CustomPainter {
  final bool isLight;
  final double animationValue;

  MatrixSquarePainter({required this.isLight, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isLight) return; // Dark squares are pure black as per request

    final paint = Paint()
      ..color = const Color(0xFF00FF41).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle vertical data lines
    final random = Random(42); // Fixed seed for stability
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.5 + random.nextDouble();
      final yOffset = (animationValue * speed * size.height) % size.height;
      
      final rectHeight = 10.0 + random.nextDouble() * 20.0;
      canvas.drawRect(
        Rect.fromLTWH(x, yOffset, 1.5, rectHeight),
        paint,
      );
      
      // Wrap around
      if (yOffset + rectHeight > size.height) {
        canvas.drawRect(
          Rect.fromLTWH(x, yOffset - size.height, 1.5, rectHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MatrixSquarePainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class DigitalPulsePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  DigitalPulsePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - animationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Expanding square pulse
    final currentSize = size.width * 0.5 + (size.width * 0.4 * animationValue);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: currentSize, height: currentSize),
      paint,
    );

    // Corner brackets
    final bracketSize = 8.0;
    final bPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final rect = Rect.fromCenter(center: center, width: size.width * 0.85, height: size.height * 0.85);
    
    // Top Left
    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.top + bracketSize)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + bracketSize, rect.top), bPaint);
    
    // Top Right
    canvas.drawPath(Path()
      ..moveTo(rect.right - bracketSize, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + bracketSize), bPaint);
      
    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(rect.left, rect.bottom - bracketSize)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + bracketSize, rect.bottom), bPaint);
      
    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(rect.right - bracketSize, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - bracketSize), bPaint);
  }

  @override
  bool shouldRepaint(DigitalPulsePainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class MatrixMoveHintPainter extends CustomPainter {
  final double animationValue;

  MatrixMoveHintPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (0.3 + 0.7 * sin(animationValue * pi)).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Digital crosshair / point
    canvas.drawRect(Rect.fromCenter(center: center, width: 4, height: 4), paint);
    
    final linePaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: opacity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
      
    canvas.drawLine(center - const Offset(8, 0), center - const Offset(4, 0), linePaint);
    canvas.drawLine(center + const Offset(4, 0), center + const Offset(8, 0), linePaint);
    canvas.drawLine(center - const Offset(0, 8), center - const Offset(0, 4), linePaint);
    canvas.drawLine(center + const Offset(0, 4), center + const Offset(0, 8), linePaint);
  }

  @override
  bool shouldRepaint(MatrixMoveHintPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}
