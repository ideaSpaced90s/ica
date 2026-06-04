import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sprite_chess_theme.dart';

class OvergrownChessTheme extends SpriteChessTheme {
  const OvergrownChessTheme()
      : super(
          id: 'sprite_overgrown',
          name: 'Overgrown',
          individualPiecesFolder: 'assets/pieces/forrest',
          lightSquare: const Color(0xDCE8F5E9), // Translucent light mint
          darkSquare: const Color(0xDC2E7D32),  // Translucent dense forest green
          frameColor: const Color(0xFF1B5E20),  // Deep moss green
        );

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF1A2718), // Deep jungle green background
      child: CustomPaint(
        painter: OvergrownBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class OvergrownBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.10) // Soft green vine
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final random = math.Random(777);

    // Draw climbing vines in 4 corners
    _drawCornerVine(canvas, paint, 0, 0, 1, 1, size, random);
    _drawCornerVine(canvas, paint, size.width, 0, -1, 1, size, random);
    _drawCornerVine(canvas, paint, 0, size.height, 1, -1, size, random);
    _drawCornerVine(canvas, paint, size.width, size.height, -1, -1, size, random);
  }

  void _drawCornerVine(Canvas canvas, Paint paint, double sx, double sy, double dx, double dy, Size size, math.Random random) {
    final path = Path()..moveTo(sx, sy);
    double curX = sx;
    double curY = sy;
    
    // Draw wavy vine line
    final steps = 5;
    final len = size.width * 0.18;
    
    for (int i = 0; i < steps; i++) {
      final targetX = sx + dx * (i + 1) * (len / steps);
      final targetY = sy + dy * (i + 1) * (len / steps);
      final wave = (-10.0 + random.nextDouble() * 20.0);
      
      final ctrlX = (curX + targetX) / 2 + wave * dy;
      final ctrlY = (curY + targetY) / 2 + wave * dx;
      
      path.quadraticBezierTo(ctrlX, ctrlY, targetX, targetY);
      
      // Draw a tiny leaf at the segment end
      _drawVineLeaf(canvas, targetX, targetY, 6.0 + random.nextDouble() * 6.0, random.nextDouble() * 2 * math.pi, random);
      
      curX = targetX;
      curY = targetY;
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawVineLeaf(Canvas canvas, double x, double y, double size, double rotation, math.Random random) {
    final leafPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF81C784).withValues(alpha: 0.08); // Very soft mint green

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -size / 2)
      ..quadraticBezierTo(size / 2.5, 0, 0, size / 2)
      ..quadraticBezierTo(-size / 2.5, 0, 0, -size / 2)
      ..close();
    canvas.drawPath(path, leafPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OvergrownBackgroundPainter oldDelegate) => false;
}
