import 'package:flutter/material.dart';
import '../utils/contrast_utility.dart';

class HighContrastPiece extends StatelessWidget {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;

  const HighContrastPiece({
    super.key,
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: CustomPaint(
        painter: HighContrastPiecePainter(
          type: type,
          isWhite: isWhite,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }
}

class HighContrastPiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;
  final bool isHighlighted;

  HighContrastPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius =
        size.width / 2.1; // Slightly smaller to allow for stroke & shadow
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Drop Shadow (Strong)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    // Draw an oval shadow slightly offset downwards
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.height * 0.45),
        width: size.width * 0.7,
        height: size.height * 0.12,
      ),
      shadowPaint,
    );

    // 2. Base Fill with Inner Gradient
    final fillPaint = Paint()
      ..color = ContrastUtility.getPieceFill(isWhite)
      ..style = PaintingStyle.fill;

    // 3. Contrasting Stroke (2px)
    final strokePaint = Paint()
      ..color = ContrastUtility.getStrokeColor(isWhite)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final path = _getPiecePath(center, radius);

    // Draw Interior Gradient for volume
    final gradientPaint = ContrastUtility.getInnerGradientPaint(rect, isWhite);

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, gradientPaint);
    canvas.drawPath(path, strokePaint);

    // 4. Rim Light (Top highlight)
    final rimPaint = ContrastUtility.getRimLightPaint(rect);
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(rect, rimPaint);
    canvas.restore();

    // If highlighted, add a subtle white glow
    if (isHighlighted) {
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4.0);
      canvas.drawPath(path, glowPaint);
    }
  }

  Path _getPiecePath(Offset center, double r) {
    switch (type.toUpperCase()) {
      case 'K':
        return _drawKing(center, r);
      case 'Q':
        return _drawQueen(center, r);
      case 'B':
        return _drawBishop(center, r);
      case 'N':
        return _drawKnight(center, r);
      case 'R':
        return _drawRook(center, r);
      case 'P':
      default:
        return _drawPawn(center, r);
    }
  }

  Path _drawKing(Offset c, double r) {
    return Path()
      ..moveTo(c.dx - r * 0.45, c.dy + r * 0.85) // Base Bottom
      ..lineTo(c.dx + r * 0.45, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.35, c.dy + r * 0.70) // Base Step
      ..lineTo(c.dx - r * 0.35, c.dy + r * 0.70)
      ..close()
      ..moveTo(c.dx - r * 0.30, c.dy + r * 0.70) // Body
      ..lineTo(c.dx + r * 0.30, c.dy + r * 0.70)
      ..lineTo(c.dx + r * 0.45, c.dy - r * 0.40) // Head base
      ..lineTo(c.dx + r * 0.15, c.dy - r * 0.45)
      ..lineTo(c.dx + r * 0.15, c.dy - r * 0.85) // Cross Top
      ..lineTo(c.dx - r * 0.15, c.dy - r * 0.85)
      ..lineTo(c.dx - r * 0.15, c.dy - r * 0.45)
      ..lineTo(c.dx - r * 0.45, c.dy - r * 0.40)
      ..close();
  }

  Path _drawQueen(Offset c, double r) {
    return Path()
      ..moveTo(c.dx - r * 0.45, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.45, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.35, c.dy + r * 0.70)
      ..lineTo(c.dx - r * 0.35, c.dy + r * 0.70)
      ..close()
      ..moveTo(c.dx - r * 0.30, c.dy + r * 0.70)
      ..lineTo(c.dx + r * 0.30, c.dy + r * 0.70)
      ..lineTo(c.dx + r * 0.60, c.dy - r * 0.50) // Crown peaks
      ..lineTo(c.dx + r * 0.25, c.dy - r * 0.25)
      ..lineTo(c.dx, c.dy - r * 0.80)
      ..lineTo(c.dx - r * 0.25, c.dy - r * 0.25)
      ..lineTo(c.dx - r * 0.60, c.dy - r * 0.50)
      ..close();
  }

  Path _drawBishop(Offset c, double r) {
    return Path()
      ..moveTo(c.dx - r * 0.35, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.35, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.25, c.dy + r * 0.65)
      ..lineTo(c.dx - r * 0.25, c.dy + r * 0.65)
      ..close()
      ..moveTo(c.dx, c.dy - r * 0.85) // Top peak
      ..cubicTo(
        c.dx + r * 0.5,
        c.dy - r * 0.2,
        c.dx + r * 0.25,
        c.dy + r * 0.65,
        c.dx,
        c.dy + r * 0.65,
      )
      ..cubicTo(
        c.dx - r * 0.25,
        c.dy + r * 0.65,
        c.dx - r * 0.5,
        c.dy - r * 0.2,
        c.dx,
        c.dy - r * 0.85,
      )
      ..close();
  }

  Path _drawKnight(Offset c, double r) {
    return Path()
      ..moveTo(c.dx - r * 0.40, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.40, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.30, c.dy + r * 0.65)
      ..lineTo(c.dx - r * 0.30, c.dy + r * 0.65)
      ..close()
      ..moveTo(c.dx - r * 0.25, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.35, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.35, c.dy - r * 0.20) // Neck
      ..lineTo(c.dx + r * 0.60, c.dy + r * 0.10) // Snout Bottom
      ..lineTo(c.dx + r * 0.65, c.dy - r * 0.30) // Nose tip
      ..lineTo(c.dx + r * 0.30, c.dy - r * 0.75) // Head top
      ..lineTo(c.dx - r * 0.10, c.dy - r * 0.75) // Ear base
      ..lineTo(c.dx - r * 0.25, c.dy - r * 0.85) // Ear tip
      ..lineTo(c.dx - r * 0.40, c.dy - r * 0.50) // Mane start
      ..lineTo(c.dx - r * 0.25, c.dy) // Mane back
      ..close();
  }

  Path _drawRook(Offset c, double r) {
    return Path()
      ..moveTo(c.dx - r * 0.45, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.45, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.40, c.dy + r * 0.65)
      ..lineTo(c.dx - r * 0.40, c.dy + r * 0.65)
      ..close()
      ..moveTo(c.dx - r * 0.35, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.35, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.35, c.dy - r * 0.60) // Tower body
      ..lineTo(c.dx + r * 0.50, c.dy - r * 0.60) // Battlement base
      ..lineTo(c.dx + r * 0.50, c.dy - r * 0.85) // Right peak
      ..lineTo(c.dx + r * 0.25, c.dy - r * 0.85)
      ..lineTo(c.dx + r * 0.25, c.dy - r * 0.70) // Notch
      ..lineTo(c.dx - r * 0.25, c.dy - r * 0.70)
      ..lineTo(c.dx - r * 0.25, c.dy - r * 0.85)
      ..lineTo(c.dx - r * 0.50, c.dy - r * 0.85) // Left peak
      ..lineTo(c.dx - r * 0.50, c.dy - r * 0.60)
      ..lineTo(c.dx - r * 0.35, c.dy - r * 0.60)
      ..close();
  }

  Path _drawPawn(Offset c, double r) {
    return Path()
      ..moveTo(c.dx - r * 0.40, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.40, c.dy + r * 0.85)
      ..lineTo(c.dx + r * 0.30, c.dy + r * 0.65)
      ..lineTo(c.dx - r * 0.30, c.dy + r * 0.65)
      ..close()
      ..moveTo(c.dx - r * 0.20, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.20, c.dy + r * 0.65)
      ..lineTo(c.dx + r * 0.15, c.dy) // Neck
      ..cubicTo(
        c.dx + r * 0.45,
        c.dy - r * 0.1,
        c.dx + r * 0.45,
        c.dy - r * 0.7,
        c.dx,
        c.dy - r * 0.7,
      ) // Head
      ..cubicTo(
        c.dx - r * 0.45,
        c.dy - r * 0.7,
        c.dx - r * 0.45,
        c.dy - r * 0.1,
        c.dx - r * 0.15,
        c.dy,
      )
      ..close();
  }

  @override
  bool shouldRepaint(covariant HighContrastPiecePainter oldDelegate) =>
      oldDelegate.isHighlighted != isHighlighted ||
      oldDelegate.isWhite != isWhite ||
      oldDelegate.type != type;
}
