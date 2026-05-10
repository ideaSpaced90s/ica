import 'package:flutter/material.dart';

class WoodenPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;

  WoodenPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final woodGradient = LinearGradient(
      colors: isWhite
          ? [const Color(0xFFD7B682), const Color(0xFF8B5A2B)]
          : [const Color(0xFF5D4037), const Color(0xFF2B1B17)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = woodGradient
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Drawing basic shapes for pieces (minimalistic but wooden)
    switch (type) {
      case 'K':
        _drawKing(canvas, center, radius, paint, strokePaint);
        break;
      case 'Q':
        _drawQueen(canvas, center, radius, paint, strokePaint);
        break;
      case 'B':
        _drawBishop(canvas, center, radius, paint, strokePaint);
        break;
      case 'N':
        _drawKnight(canvas, center, radius, paint, strokePaint);
        break;
      case 'R':
        _drawRook(canvas, center, radius, paint, strokePaint);
        break;
      default:
        _drawPawn(canvas, center, radius, paint, strokePaint);
    }
    
    // Add subtle shadow under the piece base
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(0, size.height * 0.42), width: size.width * 0.7, height: size.height * 0.1),
      shadowPaint,
    );
  }

  void _drawKing(Canvas canvas, Offset center, double radius, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.4)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.4)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.6)
      ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.6)
      ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.6)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.6)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.4)
      ..lineTo(center.dx - radius * 0.3, center.dy - radius * 0.4)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawQueen(Canvas canvas, Offset center, double radius, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.6, center.dy - radius * 0.5)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.2)
      ..lineTo(center.dx, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.3, center.dy - radius * 0.2)
      ..lineTo(center.dx - radius * 0.6, center.dy - radius * 0.5)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawBishop(Canvas canvas, Offset center, double radius, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8)
      ..cubicTo(center.dx + radius * 0.5, center.dy, center.dx, center.dy - radius * 0.9, center.dx, center.dy - radius * 0.9)
      ..cubicTo(center.dx, center.dy - radius * 0.9, center.dx - radius * 0.5, center.dy, center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    
    // Mitre cut
    final cutPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(center + Offset(0, -radius * 0.4), center + Offset(radius * 0.3, -radius * 0.7), cutPaint);
  }

  void _drawKnight(Canvas canvas, Offset center, double radius, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy - radius * 0.2)
      ..lineTo(center.dx + radius * 0.6, center.dy)
      ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.7)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.7)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.3)
      ..lineTo(center.dx - radius * 0.3, center.dy + radius * 0.1)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawRook(Canvas canvas, Offset center, double radius, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.6)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.6)
      ..lineTo(center.dx + radius * 0.5, center.dy - radius * 0.8)
      ..lineTo(center.dx + radius * 0.2, center.dy - radius * 0.8)
      ..lineTo(center.dx + radius * 0.2, center.dy - radius * 0.7)
      ..lineTo(center.dx - radius * 0.2, center.dy - radius * 0.7)
      ..lineTo(center.dx - radius * 0.2, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.8)
      ..lineTo(center.dx - radius * 0.5, center.dy - radius * 0.6)
      ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.6)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawPawn(Canvas canvas, Offset center, double radius, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.8)
      ..lineTo(center.dx + radius * 0.2, center.dy)
      ..addOval(Rect.fromCircle(center: center + Offset(0, -radius * 0.3), radius: radius * 0.35));
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant WoodenPiecePainter oldDelegate) => true;
}
