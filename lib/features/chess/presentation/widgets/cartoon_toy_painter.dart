import 'package:flutter/material.dart';

class CartoonToyPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;

  CartoonToyPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2.2;

    // 1. Material Colors (Premium Soft Plastic)
    final topColor = isWhite
        ? const Color(0xFFB2EBF2)
        : const Color(0xFFD1C4E9); // Light Blue / Light Purple
    final bottomColor = isWhite
        ? const Color(0xFF4DB6AC)
        : const Color(0xFFC62828); // Teal / Deep Red-Purple

    final plasticGradient = LinearGradient(
      colors: [topColor, bottomColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final mainPaint = Paint()
      ..shader = plasticGradient
      ..style = PaintingStyle.fill;

    // 2. Drop Shadow (Subtle lift)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path path = _getClassicToyPath(type, center, radius);

    // Draw Shadow slightly offset
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 3. Draw Base Body
    canvas.drawPath(path, mainPaint);

    // 4. Inner Highlight (Glossy look)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(
      center - Offset(radius * 0.4, radius * 0.4),
      radius * 0.5,
      highlightPaint,
    );
    canvas.restore();

    // 5. Classic Details (Eyes & Features)
    _drawFeatures(canvas, center, radius);

    // 6. Subtle Outline
    final outlinePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, outlinePaint);
  }

  Path _getClassicToyPath(String type, Offset center, double radius) {
    switch (type) {
      case 'K':
        return _kingPath(center, radius);
      case 'Q':
        return _queenPath(center, radius);
      case 'B':
        return _bishopPath(center, radius);
      case 'N':
        return _knightPath(center, radius);
      case 'R':
        return _rookPath(center, radius);
      default:
        return _pawnPath(center, radius);
    }
  }

  Path _kingPath(Offset center, double radius) {
    final path = Path();
    // Heavy Base
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.7),
          width: radius * 1.3,
          height: radius * 0.4,
        ),
        const Radius.circular(8),
      ),
    );
    // Body
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.1),
          width: radius * 0.8,
          height: radius * 1.0,
        ),
        const Radius.circular(12),
      ),
    );
    // Crown
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(0, radius * 0.5),
          width: radius * 1.0,
          height: radius * 0.35,
        ),
        const Radius.circular(6),
      ),
    );
    // Cross Top
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(0, radius * 0.75),
          width: radius * 0.25,
          height: radius * 0.6,
        ),
        const Radius.circular(4),
      ),
    );
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(0, radius * 0.75),
          width: radius * 0.6,
          height: radius * 0.2,
        ),
        const Radius.circular(4),
      ),
    );
    return path;
  }

  Path _queenPath(Offset center, double radius) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.7),
          width: radius * 1.3,
          height: radius * 0.4,
        ),
        const Radius.circular(8),
      ),
    );
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.1),
          width: radius * 0.75,
          height: radius * 1.1,
        ),
        const Radius.circular(15),
      ),
    );
    // Spiky Crown (Rounded)
    for (int i = -2; i <= 2; i++) {
      path.addOval(
        Rect.fromCircle(
          center: center + Offset(i * radius * 0.2, -radius * 0.55),
          radius: radius * 0.15,
        ),
      );
    }
    return path;
  }

  Path _bishopPath(Offset center, double radius) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.7),
          width: radius * 1.1,
          height: radius * 0.4,
        ),
        const Radius.circular(8),
      ),
    );
    path.addOval(
      Rect.fromCenter(
        center: center - Offset(0, radius * 0.05),
        width: radius * 0.8,
        height: radius * 1.1,
      ),
    );
    // Mitre Cut
    path.addOval(
      Rect.fromCircle(
        center: center - Offset(0, radius * 0.75),
        radius: radius * 0.1,
      ),
    );
    return path;
  }

  Path _knightPath(Offset center, double radius) {
    final path = Path();
    // Base
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.7),
          width: radius * 1.2,
          height: radius * 0.4,
        ),
        const Radius.circular(8),
      ),
    );
    // Arching Neck
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(radius * 0.15, radius * 0.1),
          width: radius * 0.7,
          height: radius * 0.9,
        ),
        const Radius.circular(15),
      ),
    );
    // Head Pointing Forward
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(radius * 0.15, radius * 0.15),
          width: radius * 1.0,
          height: radius * 0.6,
        ),
        const Radius.circular(12),
      ),
    );
    // Ears
    path.addOval(
      Rect.fromCircle(
        center: center + Offset(radius * 0.1, -radius * 0.55),
        radius: radius * 0.15,
      ),
    );
    return path;
  }

  Path _rookPath(Offset center, double radius) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.7),
          width: radius * 1.2,
          height: radius * 0.4,
        ),
        const Radius.circular(4),
      ),
    );
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.05),
          width: radius * 1.0,
          height: radius * 1.0,
        ),
        const Radius.circular(12),
      ),
    );
    // Battlement
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center - Offset(0, radius * 0.55),
          width: radius * 1.2,
          height: radius * 0.35,
        ),
        const Radius.circular(6),
      ),
    );
    return path;
  }

  Path _pawnPath(Offset center, double radius) {
    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center + Offset(0, radius * 0.7),
          width: radius * 1.1,
          height: radius * 0.4,
        ),
        const Radius.circular(10),
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: center + Offset(0, radius * 0.2),
        radius: radius * 0.55,
      ),
    );
    path.addOval(
      Rect.fromCircle(
        center: center - Offset(0, radius * 0.35),
        radius: radius * 0.45,
      ),
    );
    return path;
  }

  void _drawFeatures(Canvas canvas, Offset center, double radius) {
    final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.6);

    if (type == 'P' || type == 'N') {
      // Small cute eyes
      final eyeOffset = type == 'N'
          ? Offset(-radius * 0.3, -radius * 0.1)
          : Offset(0, -radius * 0.3);
      final spacing = radius * 0.15;

      canvas.drawCircle(center + eyeOffset - Offset(spacing, 0), 2.5, eyePaint);
      canvas.drawCircle(center + eyeOffset + Offset(spacing, 0), 2.5, eyePaint);
    }

    if (type == 'B') {
      // Subtle slanted mitre line
      final linePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(
        center - Offset(radius * 0.3, radius * 0.3),
        center + Offset(radius * 0.1, -radius * 0.1),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CartoonToyPiecePainter oldDelegate) => true;
}
