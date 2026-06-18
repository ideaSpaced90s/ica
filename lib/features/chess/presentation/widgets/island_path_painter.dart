import 'dart:ui';
import 'package:flutter/material.dart';

class IslandPathPainter extends CustomPainter {
  final int currentIslandIndex;
  final int totalIslands;
  final double animationValue; // for pulsing/marching ants effect

  IslandPathPainter({
    required this.currentIslandIndex,
    required this.totalIslands,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double verticalSpacing = 135.0;
    final double xOffset = 45.0;
    final double bottomPadding = 80.0;

    Offset getIslandPos(int index) {
      final double y = size.height - bottomPadding - (index * verticalSpacing);
      final double x = centerX + ((index % 2 == 0) ? -xOffset : xOffset);
      return Offset(x, y);
    }

    for (int i = 0; i < totalIslands - 1; i++) {
      final Offset start = getIslandPos(i);
      final Offset end = getIslandPos(i + 1);

      // Create a smooth S-curve path between the islands
      final Path path = Path();
      path.moveTo(start.dx, start.dy);
      // Control point pulls the curve towards the center line
      final Offset controlPoint = Offset(centerX, (start.dy + end.dy) / 2);
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

      // Determine segment state
      final bool isCompleted = i < currentIslandIndex;
      final bool isActive = i == currentIslandIndex;

      if (isCompleted) {
        // Gold solid path
        final Paint paint = Paint()
          ..color = const Color(0xFFF59E0B) // warm gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, paint);
      } else if (isActive) {
        // Marching ants / dashed blue path
        final Paint paint = Paint()
          ..color = const Color(0xFF0D6EFD) // accent blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;

        // Draw dashed path using metrics
        final PathMetrics metrics = path.computeMetrics();
        for (final PathMetric metric in metrics) {
          double distance = animationValue * 15.0; // marching animation offset
          while (distance < metric.length) {
            final Path extract = metric.extractPath(distance, distance + 6.0);
            canvas.drawPath(extract, paint);
            distance += 15.0; // dash + gap
          }
        }
      } else {
        // Muted gray dotted path
        final Paint paint = Paint()
          ..color = const Color(0xFFD1D5DB) // gray-300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;

        final PathMetrics metrics = path.computeMetrics();
        for (final PathMetric metric in metrics) {
          double distance = 0.0;
          while (distance < metric.length) {
            final Path extract = metric.extractPath(distance, distance + 3.0);
            canvas.drawPath(extract, paint);
            distance += 10.0;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslandPathPainter oldDelegate) {
    return oldDelegate.currentIslandIndex != currentIslandIndex ||
        oldDelegate.animationValue != animationValue;
  }
}
