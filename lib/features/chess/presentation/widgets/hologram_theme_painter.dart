import 'dart:math';
import 'package:flutter/material.dart';

class HologramBoardPainter extends CustomPainter {
  final bool isLight;
  final double animationValue;

  HologramBoardPainter({required this.isLight, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark navy squares are handled by the boardTheme.darkSquare
    // We only add overlays here if needed, but per-square grid lines are better.
    
    final cyanGlow = const Color(0xFF22D3EE);
    final purpleGlow = const Color(0xFFA78BFA);
    final baseColor = isLight ? cyanGlow : purpleGlow;

    // 1. Subtle inner square glow
    final Rect rect = Offset.zero & size;
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.15),
          baseColor.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(rect);
    
    canvas.drawRect(rect, glowPaint);

    // 2. Sci-fi Grid Lines (edges of the square)
    final Paint linePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw partial corners for a techy look
    final double cornerLen = size.width * 0.2;
    
    // Top-left corner
    canvas.drawLine(Offset.zero, Offset(cornerLen, 0), linePaint);
    canvas.drawLine(Offset.zero, Offset(0, cornerLen), linePaint);

    // Top-right corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), linePaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), linePaint);

    // Bottom-left corner
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), linePaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), linePaint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), linePaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), linePaint);

    // 3. Data pulse effect (subtle flashing lines)
    if (sin(animationValue * 3 * pi) > 0.7) {
      final pulsePaint = Paint()
        ..color = baseColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      
      canvas.drawLine(
        Offset(0, size.height * 0.5), 
        Offset(size.width, size.height * 0.5), 
        pulsePaint
      );
    }
  }

  @override
  bool shouldRepaint(HologramBoardPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class HoloSelectionPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  HoloSelectionPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;
    
    final Paint ringPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Rotating holographic ring
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * pi);
    
    // Draw 4 segments
    const double sweep = pi / 4;
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        (i * pi / 2),
        sweep,
        false,
        ringPaint,
      );
    }
    
    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(Offset.zero, radius, glowPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(HoloSelectionPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}

class HoloMoveHintPainter extends CustomPainter {
  final double animationValue;
  final bool isEnemy;

  HoloMoveHintPainter({required this.animationValue, required this.isEnemy});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color = isEnemy ? const Color(0xFFFF5555) : const Color(0xFF22D3EE);
    
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6 + 0.4 * sin(animationValue * 2 * pi))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (!isEnemy) {
      // Floating hexagonal/diamond marker
      final double r = 6.0;
      final path = Path()
        ..moveTo(center.dx, center.dy - r)
        ..lineTo(center.dx + r, center.dy)
        ..lineTo(center.dx, center.dy + r)
        ..lineTo(center.dx - r, center.dy)
        ..close();
      
      canvas.drawPath(path, paint);
      
      // Outer glow
      canvas.drawPath(path, Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    } else {
      // Target brackets for enemy capture
      final double s = size.width * 0.4;
      final double l = 8.0;
      
      canvas.drawLine(center + Offset(-s, -s), center + Offset(-s + l, -s), paint);
      canvas.drawLine(center + Offset(-s, -s), center + Offset(-s, -s + l), paint);
      
      canvas.drawLine(center + Offset(s, -s), center + Offset(s - l, -s), paint);
      canvas.drawLine(center + Offset(s, -s), center + Offset(s, -s + l), paint);
      
      canvas.drawLine(center + Offset(-s, s), center + Offset(-s + l, s), paint);
      canvas.drawLine(center + Offset(-s, s), center + Offset(-s, s - l), paint);
      
      canvas.drawLine(center + Offset(s, s), center + Offset(s - l, s), paint);
      canvas.drawLine(center + Offset(s, s), center + Offset(s, s - l), paint);
    }
  }

  @override
  bool shouldRepaint(HoloMoveHintPainter oldDelegate) => true;
}
