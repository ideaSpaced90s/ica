import 'dart:math';
import 'package:flutter/material.dart';

class ElectricGridPainter extends CustomPainter {
  final bool isLight;
  final double animationValue;

  ElectricGridPainter({required this.isLight, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isLight) return; // Dark squares stay mostly black

    final mainBlue = const Color(0xFF00BFFF);
    final paint = Paint()
      ..color = mainBlue.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw a subtle circuit/grid pattern
    final double step = size.width / 4;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Occasional "energy pulse" on the grid lines
    if (sin(animationValue * 2 * pi) > 0.8) {
      final pulsePaint = Paint()
        ..color = mainBlue.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      
      final pulsePos = (animationValue * size.width) % size.width;
      canvas.drawLine(Offset(pulsePos, 0), Offset(pulsePos, size.height), pulsePaint);
    }
  }

  @override
  bool shouldRepaint(ElectricGridPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class EnergySurgePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  EnergySurgePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random(42);
    
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - animationValue).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Multiple expanding rings with jitter
    for (int i = 0; i < 3; i++) {
        final radius = (size.width * 0.3) + (size.width * 0.6 * ((animationValue + i*0.2) % 1.0));
        final jitter = (random.nextDouble() - 0.5) * 5.0;
        canvas.drawCircle(center, radius + jitter, paint);
    }

    // Energy arcs
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 4; i++) {
      final angle = (animationValue * 2 * pi) + (i * pi / 2);
      final r1 = size.width * 0.3;
      final r2 = size.width * 0.45;
      
      canvas.drawLine(
        Offset(center.dx + cos(angle) * r1, center.dy + sin(angle) * r1),
        Offset(center.dx + cos(angle + 0.2) * r2, center.dy + sin(angle + 0.2) * r2),
        arcPaint
      );
    }
  }

  @override
  bool shouldRepaint(EnergySurgePainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class SparkNodeHintPainter extends CustomPainter {
  final double animationValue;

  SparkNodeHintPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random();
    
    final paint = Paint()
      ..color = const Color(0xFF00BFFF)
      ..style = PaintingStyle.fill;

    // Glowing core
    canvas.drawCircle(center, 3, paint);
    
    // Spark branches
    if (random.nextDouble() > 0.4) {
      final sparkPaint = Paint()
        ..color = const Color(0xFFE0FFFF).withValues(alpha: 0.8)
        ..strokeWidth = 1.0;
        
      for (int i = 0; i < 3; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final length = 5.0 + random.nextDouble() * 10.0;
        canvas.drawLine(
          center,
          Offset(center.dx + cos(angle) * length, center.dy + sin(angle) * length),
          sparkPaint
        );
      }
    }
  }

  @override
  bool shouldRepaint(SparkNodeHintPainter oldDelegate) => true;
}
