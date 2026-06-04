import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sprite_chess_theme.dart';

class PlasmaChessTheme extends SpriteChessTheme {
  const PlasmaChessTheme()
      : super(
          id: 'sprite_plasma',
          name: 'Plasma',
          individualPiecesFolder: 'assets/pieces/energy-webP',
          pieceExtension: 'webp',
          lightSquare: const Color(0xDC0D1117), // Translucent dark slate
          darkSquare: const Color(0xDC0F2C59),  // Translucent plasma indigo
          frameColor: const Color(0xFF00BFFF),  // Neon cyan
        );

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF070B11), // Deep neon abyss background
      child: CustomPaint(
        painter: PlasmaBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class PlasmaBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00BFFF).withValues(alpha: 0.05); // Very soft neon cyan

    final random = math.Random(8888);

    // 1. Draw glowing circular energy cells
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 30.0 + random.nextDouble() * 60.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // 2. Draw small drifting plasma nodes
    paint.color = const Color(0xFF00E5FF).withValues(alpha: 0.08);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PlasmaBackgroundPainter oldDelegate) => false;
}
