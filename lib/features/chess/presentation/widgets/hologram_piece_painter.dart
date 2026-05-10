import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class HoloPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final double animationValue;

  HoloPiecePainter({
    required this.type,
    required this.isWhite,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cyanGlow = const Color(0xFF22D3EE);
    final purpleGlow = const Color(0xFFA78BFA);
    final Color baseColor = isWhite ? cyanGlow : purpleGlow;

    final Paint borderPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint fillPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.15 + (0.05 * sin(animationValue * 4 * pi)))
      ..style = PaintingStyle.fill;

    final Paint glowPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3.0);

    final Path path = _getPiecePath(type, size);

    // 1. Outer Glow
    canvas.drawPath(path, glowPaint);
    
    // 2. Semi-transparent Interior
    canvas.drawPath(path, fillPaint);
    
    // 3. Sharp Edge lines
    canvas.drawPath(path, borderPaint);

    // 4. Tech detail lines inside the piece
    _drawTechDetails(canvas, path, size, baseColor);
    
    // 5. Flicker Effect
    if (sin(animationValue * 10 * pi) > 0.95) {
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.2));
    }
  }

  void _drawTechDetails(Canvas canvas, Path path, Size size, Color color) {
    final Paint linePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Draw 3 horizontal scanline details within the piece
    for (int i = 1; i < 4; i++) {
        final double y = (size.height / 4) * i;
        // Clip to the piece path
        canvas.save();
        canvas.clipPath(path);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
        canvas.restore();
    }
  }

  Path _getPiecePath(chess_lib.PieceType type, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    switch (type) {
      case chess_lib.PieceType.PAWN:
        path.moveTo(midX, h * 0.2);
        path.lineTo(midX + w * 0.15, h * 0.35);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.2, h * 0.75);
        path.lineTo(midX - w * 0.15, h * 0.35);
        path.close();
        break;
      case chess_lib.PieceType.KNIGHT:
        path.moveTo(midX - w * 0.1, h * 0.2);
        path.lineTo(midX + w * 0.25, h * 0.35);
        path.lineTo(midX + w * 0.1, h * 0.55);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.45);
        path.close();
        break;
      case chess_lib.PieceType.BISHOP:
        path.moveTo(midX, h * 0.15);
        path.lineTo(midX + w * 0.2, h * 0.45);
        path.lineTo(midX + w * 0.1, h * 0.75);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.1, h * 0.75);
        path.lineTo(midX - w * 0.2, h * 0.45);
        path.close();
        break;
      case chess_lib.PieceType.ROOK:
        path.moveTo(midX - w * 0.25, h * 0.2);
        path.lineTo(midX - w * 0.15, h * 0.2);
        path.lineTo(midX - w * 0.15, h * 0.3);
        path.lineTo(midX + w * 0.15, h * 0.3);
        path.lineTo(midX + w * 0.15, h * 0.2);
        path.lineTo(midX + w * 0.25, h * 0.2);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX - w * 0.25, h * 0.85);
        path.close();
        break;
      case chess_lib.PieceType.QUEEN:
        path.moveTo(midX, h * 0.1);
        path.lineTo(midX + w * 0.3, h * 0.3);
        path.lineTo(midX + w * 0.2, h * 0.6);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX - w * 0.2, h * 0.6);
        path.lineTo(midX - w * 0.3, h * 0.3);
        path.close();
        break;
      case chess_lib.PieceType.KING:
        // Crown shape
        path.moveTo(midX - w * 0.1, h * 0.05);
        path.lineTo(midX + w * 0.1, h * 0.05);
        path.lineTo(midX + w * 0.1, h * 0.15);
        path.lineTo(midX + w * 0.3, h * 0.15);
        path.lineTo(midX + w * 0.3, h * 0.25);
        path.lineTo(midX + w * 0.1, h * 0.25);
        path.lineTo(midX + w * 0.1, h * 0.35);
        path.lineTo(midX + w * 0.35, h * 0.85);
        path.lineTo(midX - w * 0.35, h * 0.85);
        path.lineTo(midX - w * 0.1, h * 0.35);
        path.lineTo(midX - w * 0.1, h * 0.25);
        path.lineTo(midX - w * 0.3, h * 0.25);
        path.lineTo(midX - w * 0.3, h * 0.15);
        path.lineTo(midX - w * 0.1, h * 0.15);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(HoloPiecePainter oldDelegate) => true;
}
