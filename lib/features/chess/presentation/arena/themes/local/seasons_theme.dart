import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../global/sprite_chess_theme.dart';

class SeasonsChessTheme extends SpriteChessTheme {
  const SeasonsChessTheme()
      : super(
          id: 'sprite_seasons',
          name: 'Seasons',
          individualPiecesFolder: 'assets/pieces/summernautumn',
          lightSquare: const Color(0xDCF3EFE0), // Translucent Birch Cream (86% opacity)
          darkSquare: const Color(0xDC6E7E60),  // Translucent Forest Moss Green (86% opacity)
          frameColor: const Color(0xFF5C4033),  // Faded Bark Brown
        );

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFAF6EE), // Very light soft cream/amber
            Color(0xFFE8ECE5), // Very light woodland misty green
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomPaint(
        painter: SeasonsBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class SeasonsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42); // Fixed seed to keep elements static

    // 1. Draw soft grass blades at the bottom edge
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    
    // Mossy Green grass
    paint.color = const Color(0xFF6E7E60).withValues(alpha: 0.12);
    for (int i = 0; i < 45; i++) {
      final x = random.nextDouble() * size.width;
      final h = 8.0 + random.nextDouble() * 20.0;
      final bend = -5.0 + random.nextDouble() * 10.0;
      paint.strokeWidth = 1.5 + random.nextDouble() * 2.0;

      final path = Path()
        ..moveTo(x, size.height)
        ..quadraticBezierTo(x + bend, size.height - h / 2, x + bend * 1.5, size.height - h);
      canvas.drawPath(path, paint);
    }

    // 2. Draw soft 2D minimalist trees in the bottom-left and bottom-right corners
    paint.style = PaintingStyle.fill;
    
    // Draw 3 trees on Left corner
    _drawMinimalistTree(canvas, paint, 25.0, size.height - 10.0, 50.0, const Color(0xFF6E7E60));
    _drawMinimalistTree(canvas, paint, 55.0, size.height - 5.0, 35.0, const Color(0xFF5A6B4F));
    _drawMinimalistTree(canvas, paint, 80.0, size.height - 8.0, 42.0, const Color(0xFF8A9A80));

    // Draw 3 trees on Right corner
    _drawMinimalistTree(canvas, paint, size.width - 30.0, size.height - 12.0, 48.0, const Color(0xFF6E7E60));
    _drawMinimalistTree(canvas, paint, size.width - 65.0, size.height - 6.0, 38.0, const Color(0xFF8A9A80));
    _drawMinimalistTree(canvas, paint, size.width - 90.0, size.height - 10.0, 40.0, const Color(0xFF5A6B4F));

    // 3. Draw drifting leaves (summer/autumn) along the borders and corners
    paint.style = PaintingStyle.fill;
    final leafColors = [
      const Color(0xFFE28743).withValues(alpha: 0.08), // Autumn Orange
      const Color(0xFFC5A059).withValues(alpha: 0.08), // Golden Yellow
      const Color(0xFF6E7E60).withValues(alpha: 0.07), // Summer Green
      const Color(0xFFB85A3E).withValues(alpha: 0.06), // Rust Red
    ];

    // Scatter 26 leaves primarily around the edges
    for (int i = 0; i < 26; i++) {
      double x, y;
      // Force leaves to outer borders/margins
      if (i < 10) {
        // Top border
        x = random.nextDouble() * size.width;
        y = random.nextDouble() * (size.height * 0.12);
      } else if (i < 20) {
        // Bottom border (above grass)
        x = random.nextDouble() * size.width;
        y = size.height - (random.nextDouble() * (size.height * 0.15));
      } else {
        // Sides
        x = random.nextBool() ? random.nextDouble() * (size.width * 0.12) : size.width - (random.nextDouble() * (size.width * 0.12));
        y = random.nextDouble() * size.height;
      }

      final sizeFactor = 6.0 + random.nextDouble() * 10.0;
      final rotation = random.nextDouble() * 2 * math.pi;
      final color = leafColors[random.nextInt(leafColors.length)];

      _drawLeaf(canvas, paint, x, y, sizeFactor, rotation, color);
    }
  }

  void _drawMinimalistTree(Canvas canvas, Paint paint, double x, double y, double height, Color color) {
    // Tree trunk
    paint.color = const Color(0xFF5C4033).withValues(alpha: 0.08);
    canvas.drawRect(Rect.fromLTWH(x - 2, y - height, 4, height), paint);

    // Leaves crown (2D layered triangles)
    paint.color = color.withValues(alpha: 0.08);
    final levels = 3;
    final baseWidth = height * 0.45;
    for (int i = 0; i < levels; i++) {
      final levelHeight = height * 0.35;
      final levelY = y - height + (i * levelHeight * 0.6);
      final levelWidth = baseWidth * (1.0 - (i * 0.25));

      final path = Path()
        ..moveTo(x, levelY - levelHeight)
        ..lineTo(x - levelWidth / 2, levelY)
        ..lineTo(x + levelWidth / 2, levelY)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint, double x, double y, double size, double rotation, Color color) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    paint.color = color;
    
    // Draw simple pointed leaf path
    final path = Path()
      ..moveTo(0, -size / 2)
      ..quadraticBezierTo(size / 2.5, 0, 0, size / 2)
      ..quadraticBezierTo(-size / 2.5, 0, 0, -size / 2)
      ..close();
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SeasonsBackgroundPainter oldDelegate) => false;
}
