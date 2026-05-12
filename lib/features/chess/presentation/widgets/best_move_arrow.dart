import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../scholarly_theme.dart';

class BestMoveArrowOverlay extends StatelessWidget {
  final String from;
  final String to;
  final double boardSize;
  final bool isFlipped;

  const BestMoveArrowOverlay({
    super.key,
    required this.from,
    required this.to,
    required this.boardSize,
    required this.isFlipped,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size(boardSize, boardSize),
        painter: ArrowPainter(
          from: from,
          to: to,
          isFlipped: isFlipped,
          squareSize: boardSize / 8,
        ),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final String from;
  final String to;
  final bool isFlipped;
  final double squareSize;

  ArrowPainter({
    required this.from,
    required this.to,
    required this.isFlipped,
    required this.squareSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final start = _getCenter(from);
    final end = _getCenter(to);

    final paint = Paint()
      ..color = ScholarlyTheme.accentGold.withValues(alpha: 0.8)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final headPaint = Paint()
      ..color = ScholarlyTheme.accentGold.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Draw line with a small gap at the end for the arrowhead
    final direction = end - start;
    final length = direction.distance;
    final unitDirection = direction / length;
    final lineEnd = end - unitDirection * 15;

    canvas.drawLine(start, lineEnd, paint);

    // Draw arrowhead
    final angle = math.atan2(direction.dy, direction.dx);
    const arrowSize = 18.0;
    const arrowAngle = 0.5; // radians

    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowSize * math.cos(angle - arrowAngle),
      end.dy - arrowSize * math.sin(angle - arrowAngle),
    );
    path.lineTo(
      end.dx - arrowSize * math.cos(angle + arrowAngle),
      end.dy - arrowSize * math.sin(angle + arrowAngle),
    );
    path.close();

    canvas.drawPath(path, headPaint);

    // Add a subtle glow
    final glowPaint = Paint()
      ..color = ScholarlyTheme.accentGold.withValues(alpha: 0.3)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, lineEnd, glowPaint);
  }

  Offset _getCenter(String square) {
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);

    final x = (isFlipped ? 7 - col : col) * squareSize + squareSize / 2;
    final y = (isFlipped ? 7 - row : row) * squareSize + squareSize / 2;
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) =>
      oldDelegate.from != from ||
      oldDelegate.to != to ||
      oldDelegate.isFlipped != isFlipped;
}
