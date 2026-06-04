import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sprite_chess_theme.dart';

class LightningChessTheme extends SpriteChessTheme {
  const LightningChessTheme()
      : super(
          id: 'sprite_lightning',
          name: 'Lightning',
          individualPiecesFolder: 'assets/pieces/lightening-webP',
          pieceExtension: 'webp',
          lightSquare: const Color(0xDCFAEBD7), // Translucent light cream
          darkSquare: const Color(0xDC0A1128),  // Translucent dark midnight blue
          frameColor: const Color(0xFF00E5FF),  // Neon electric blue
        );

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF020617), // Deep dark space background
      child: CustomPaint(
        painter: LightningBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class LightningBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.08) // Soft electric cyan
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    final random = math.Random(1337);

    // Draw 3-4 soft lightning paths across the border
    for (int i = 0; i < 4; i++) {
      final side = random.nextInt(4); // 0: Top, 1: Right, 2: Bottom, 3: Left
      double startX = 0, startY = 0;
      double endX = 0, endY = 0;

      if (side == 0) {
        startX = random.nextDouble() * size.width;
        startY = 0;
        endX = startX + (-50 + random.nextDouble() * 100);
        endY = size.height * 0.25;
      } else if (side == 1) {
        startX = size.width;
        startY = random.nextDouble() * size.height;
        endX = size.width - (size.width * 0.25);
        endY = startY + (-50 + random.nextDouble() * 100);
      } else if (side == 2) {
        startX = random.nextDouble() * size.width;
        startY = size.height;
        endX = startX + (-50 + random.nextDouble() * 100);
        endY = size.height - (size.height * 0.25);
      } else {
        startX = 0;
        startY = random.nextDouble() * size.height;
        endX = size.width * 0.25;
        endY = startY + (-50 + random.nextDouble() * 100);
      }

      _drawFractalLightning(canvas, paint, startX, startY, endX, endY, random);
    }
  }

  void _drawFractalLightning(Canvas canvas, Paint paint, double x1, double y1, double x2, double y2, math.Random random) {
    final path = Path()..moveTo(x1, y1);

    final segments = 6;
    
    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      // Target straight line point
      final targetX = x1 + (x2 - x1) * t;
      final targetY = y1 + (y2 - y1) * t;

      // Jitter
      final jitterX = (-12.0 + random.nextDouble() * 24.0) * (1.0 - t * 0.5);
      final jitterY = (-12.0 + random.nextDouble() * 24.0) * (1.0 - t * 0.5);

      path.lineTo(targetX + jitterX, targetY + jitterY);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LightningBackgroundPainter oldDelegate) => false;
}
