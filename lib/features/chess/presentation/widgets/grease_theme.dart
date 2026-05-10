import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Industrial Grease Theme Colors
class GreaseColors {
  static const dirtyYellow = Color(0xFFD4A017);
  static const oilBlack = Color(0xFF2B2B2B);
  static const darkOil = Color(0xFF111111);
  static const lightSquare = Color(0xFF8D6E63);
  static const darkSquare = Color(0xFF3E2723);
  static const rust = Color(0xFF5D4037);
  static const hazardYellow = Color(0xFFFFD600);
}

class GreaseBoardPainter extends CustomPainter {
  final bool isLight;
  final double animationValue;

  GreaseBoardPainter({required this.isLight, this.animationValue = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final random = math.Random(isLight ? 123 : 456);

    // 1. Base Square Color
    final baseColor = isLight 
        ? GreaseColors.lightSquare.withValues(alpha: 0.85) 
        : GreaseColors.darkSquare;
    
    final Paint paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

    // 2. Add Metallic Noise / Texture
    final noisePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, noisePaint);

    // 3. Oil Stains & Smudges
    for (int i = 0; i < 3; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double r = random.nextDouble() * size.width * 0.4;
      
      final stainPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            GreaseColors.darkOil.withValues(alpha: 0.4),
            GreaseColors.darkOil.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r));
      
      canvas.drawCircle(Offset(x, y), r, stainPaint);
    }

    // 4. Circular Grease Marks
    if (random.nextDouble() > 0.5) {
      final cyclePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5), 
        size.width * 0.3, 
        cyclePaint
      );
    }

    // 5. Worn Edges
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(rect.deflate(0.5), edgePaint);
  }

  @override
  bool shouldRepaint(GreaseBoardPainter oldDelegate) => false;
}

class IndustrialPiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;
  final double rotation;

  IndustrialPiecePainter({
    required this.type,
    required this.isWhite,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.42;

    // 1. Material Paint
    final mainColor = isWhite ? GreaseColors.dirtyYellow : GreaseColors.oilBlack;
    final accentColor = isWhite ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.3);

    final Paint materialPaint = Paint()
      ..shader = LinearGradient(
        colors: [mainColor, mainColor.withValues(alpha: 0.8), mainColor.withValues(alpha: 0.6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Paint accentPaint = Paint()
      ..shader = LinearGradient(
        colors: [accentColor.withValues(alpha: 0.1), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final strokePaint = Paint()
      ..color = isWhite ? Colors.black : Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final Path path = _getIndustrialPath(type, center, radius);

    // Draw Heavy Shadow
    canvas.drawPath(path.shift(const Offset(3, 3)), Paint()..color = Colors.black.withValues(alpha: 0.4));

    // Draw Body
    canvas.drawPath(path, materialPaint);
    canvas.drawPath(path, accentPaint);
    canvas.drawPath(path, strokePaint);


    // 2. Add Rust & Scratches
    _addGrime(canvas, path, center, radius);

    // 3. Iconic Features
    _addIndustrialDetails(canvas, type, center, radius, rotation);
  }

  void _addGrime(Canvas canvas, Path path, Offset center, double radius) {
    final rustPaint = Paint()
      ..color = GreaseColors.rust.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    
    // Subtle rust on edges
    canvas.save();
    canvas.clipPath(path);
    canvas.drawCircle(center + Offset(radius * 0.5, radius * 0.5), radius * 0.4, rustPaint);
    canvas.restore();
  }

  void _addIndustrialDetails(Canvas canvas, String type, Offset center, double radius, double rotation) {
    final detailPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    
    // Bolts
    canvas.drawCircle(center + Offset(-radius * 0.4, radius * 0.6), 1.5, detailPaint);
    canvas.drawCircle(center + Offset(radius * 0.4, radius * 0.6), 1.5, detailPaint);

    if (type == 'K') {
      // Rotating gear crown
      _drawGear(canvas, center + Offset(0, -radius * 0.7), radius * 0.4, rotation, Colors.grey);
    } else if (type == 'Q') {
      // Layered gears
      _drawGear(canvas, center + Offset(0, -radius * 0.2), radius * 0.5, rotation, Colors.grey);
      _drawGear(canvas, center + Offset(0, -radius * 0.5), radius * 0.3, -rotation * 1.5, Colors.blueGrey);
    }
  }

  void _drawGear(Canvas canvas, Offset center, double radius, double rotation, Color color) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);
    
    final Path gear = Path();
    const int teeth = 8;
    for (int i = 0; i < teeth * 2; i++) {
        final r = i.isEven ? radius : radius * 1.2;
        final angle = (i / (teeth * 2)) * 2 * math.pi;
        if (i == 0) {
          gear.moveTo(math.cos(angle) * r, math.sin(angle) * r);
        } else {
          gear.lineTo(math.cos(angle) * r, math.sin(angle) * r);
        }
    }
    gear.close();
    canvas.drawPath(gear, paint);
    canvas.drawCircle(Offset.zero, radius * 0.4, Paint()..color = Colors.black.withValues(alpha: 0.4));
    canvas.restore();
  }

  Path _getIndustrialPath(String type, Offset center, double radius) {
    switch (type) {
      case 'K': // Central pillar
        return Path()
          ..moveTo(center.dx - radius * 0.5, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.5, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.4, center.dy - radius * 0.5)
          ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.5)
          ..close();
      case 'Q': // Wider gear body
        return Path()
          ..moveTo(center.dx - radius * 0.6, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.6, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.7, center.dy - radius * 0.1)
          ..lineTo(center.dx - radius * 0.7, center.dy - radius * 0.1)
          ..close();
      case 'R': // Hydraulic press
        return Path()
          ..addRect(Rect.fromCenter(center: center + Offset(0, radius * 0.3), width: radius * 1.2, height: radius * 0.8))
          ..addRect(Rect.fromCenter(center: center - Offset(0, radius * 0.4), width: radius * 0.8, height: radius * 0.6));
      case 'B': // Cutter head
        return Path()
          ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
          ..lineTo(center.dx, center.dy - radius * 0.8)
          ..close()
          ..moveTo(center.dx - radius * 0.2, center.dy - radius * 0.2)
          ..lineTo(center.dx + radius * 0.2, center.dy + radius * 0.2);
      case 'N': // Mechanical claw
        return Path()
          ..moveTo(center.dx - radius * 0.2, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.2, center.dy + radius * 0.8)
          ..quadraticBezierTo(center.dx + radius * 0.8, center.dy, center.dx, center.dy - radius * 0.8)
          ..lineTo(center.dx - radius * 0.4, center.dy - radius * 0.4)
          ..close();
      case 'P': // Bolt unit
      default:
        return Path()
          ..moveTo(center.dx - radius * 0.4, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.4, center.dy + radius * 0.8)
          ..lineTo(center.dx + radius * 0.3, center.dy + radius * 0.2)
          ..addOval(Rect.fromCircle(center: center + Offset(0, -radius * 0.2), radius: radius * 0.5));
    }
  }

  @override
  bool shouldRepaint(covariant IndustrialPiecePainter oldDelegate) => 
    oldDelegate.rotation != rotation;
}

class GreaseSelectionPainter extends CustomPainter {
  final double animationValue;

  GreaseSelectionPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.46;


    // Hazard Ring (Yellow/Black stripes)
    final Paint ringPaint = Paint()
      ..color = GreaseColors.hazardYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, ringPaint);

    final stripePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * math.pi);
    
    for (int i = 0; i < 12; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        (i * math.pi / 6),
        math.pi / 12,
        false,
        stripePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GreaseSelectionPainter oldDelegate) => true;
}

class OilPuddleIndicator extends StatelessWidget {
  final bool isEnemy;
  const OilPuddleIndicator({super.key, this.isEnemy = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: isEnemy ? 45 : 18,
        height: isEnemy ? 45 : 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
          gradient: RadialGradient(
            colors: [
              GreaseColors.darkOil,
              GreaseColors.darkOil.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
