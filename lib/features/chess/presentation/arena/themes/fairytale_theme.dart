import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sprite_chess_theme.dart';

class FairytaleChessTheme extends SpriteChessTheme {
  const FairytaleChessTheme()
      : super(
          id: 'sprite_fairytale',
          name: 'Fairytale',
          individualPiecesFolder: 'assets/pieces/fairytale_castle',
          lightSquare: const Color(0xDCE7DEC9), // Translucent parchment ivory
          darkSquare: const Color(0xDC5C5346),  // Translucent old cobblestone
          frameColor: const Color(0xFF3E3930),  // Castle wall grey
        );

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF1E1A14), // Old rustic wood/stone background
      child: CustomPaint(
        painter: FairytaleBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class FairytaleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.05); // Very soft glowing gold

    final random = math.Random(1111);

    // 1. Draw soft star dust sparkles
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final sparkleSize = 2.0 + random.nextDouble() * 3.0;
      _drawSparkle(canvas, x, y, sparkleSize);
    }

    // 2. Draw minimalist soft 2D castle tower silhouettes in bottom corners
    paint.color = const Color(0xFFE7DEC9).withValues(alpha: 0.06); // Extremely soft parchment color
    
    // Left corner tower
    _drawTower(canvas, paint, 30.0, size.height, 40.0, 65.0);
    // Right corner tower
    _drawTower(canvas, paint, size.width - 70.0, size.height, 40.0, 65.0);
  }

  void _drawSparkle(Canvas canvas, double x, double y, double size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.08);

    final path = Path()
      ..moveTo(x, y - size)
      ..quadraticBezierTo(x, y, x + size, y)
      ..quadraticBezierTo(x, y, x, y + size)
      ..quadraticBezierTo(x, y, x - size, y)
      ..quadraticBezierTo(x, y, x, y - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawTower(Canvas canvas, Paint paint, double x, double y, double width, double height) {
    // Main body
    canvas.drawRect(Rect.fromLTWH(x, y - height, width, height), paint);
    
    // Parapets/teeth on top
    final teethCount = 3;
    final toothWidth = width / (teethCount * 2 - 1);
    final toothHeight = 6.0;
    
    for (int i = 0; i < teethCount; i++) {
      final tx = x + (i * 2 * toothWidth);
      canvas.drawRect(Rect.fromLTWH(tx, y - height - toothHeight, toothWidth, toothHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant FairytaleBackgroundPainter oldDelegate) => false;
}
