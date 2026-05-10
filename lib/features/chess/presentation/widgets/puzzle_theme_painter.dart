import 'package:flutter/material.dart';

class PuzzleSquarePainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  PuzzleSquarePainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    // Draw main square body
    final R = 4.0; // Corner radius
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(R),
      ),
      paint,
    );

    // Draw a subtle bevel/plastic look
    final Color highlightColor = Colors.white.withValues(alpha: 0.15);
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
        Radius.circular(R),
      ),
      highlightPaint,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), shadowPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PuzzleMoveIndicator extends StatelessWidget {
  final bool isEnemy;
  const PuzzleMoveIndicator({super.key, this.isEnemy = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isEnemy ? Colors.redAccent.withValues(alpha: 0.4) : Colors.greenAccent.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEnemy ? Colors.red : Colors.greenAccent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isEnemy ? Colors.red : Colors.greenAccent).withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          // Inner "stud"
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: (isEnemy ? Colors.red : Colors.greenAccent).withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class PuzzleSelectionCradle extends StatelessWidget {
  const PuzzleSelectionCradle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
