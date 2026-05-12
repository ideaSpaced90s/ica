import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

/// A premium, highly detailed 3D programmatic vector piece widget for the Royal Theme.
class RoyalVectorPiece extends StatelessWidget {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue;

  const RoyalVectorPiece({
    super.key,
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
    this.animationValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: RoyalVectorPiecePainter(
          type: type,
          isWhite: isWhite,
          isHighlighted: isHighlighted,
          animationValue: animationValue,
        ),
      ),
    );
  }
}

/// Master custom painter rendering fine 3D volumetric details, soft occlusion shadows,
/// embedded polished gold accent rings, and unique front-to-back geometric layers.
class RoyalVectorPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue;

  RoyalVectorPiecePainter({
    required this.type,
    required this.isWhite,
    required this.isHighlighted,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    // Helper to fill and apply requested thin black border to white pieces only
    void drawShape(Path path, Paint fill) {
      canvas.drawPath(path, fill);
      if (isWhite) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = Colors.black.withValues(alpha: 0.85),
        );
      }
    }

    // --- 1. Global Perspective Base Drop Shadow ---
    final Path shadowPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(midX + w * 0.04, h * 0.88),
          width: w * 0.75,
          height: h * 0.18));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    // --- 2. Material Shaders & Dynamic Lighting ---
    final Paint bodyPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? [
                const Color(0xFFFFFFFF),
                const Color(0xFFF1F5F9),
                const Color(0xFFCBD5E1),
              ]
            : [
                const Color(0xFF334155),
                const Color(0xFF0F172A),
                const Color(0xFF020617),
              ],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    final Paint goldPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFFCA8A04),
          Color(0xFFFEF08A),
          Color(0xFFEAB308),
          Color(0xFF713F12),
          Color(0xFFFACC15),
        ],
        stops: const [0.0, 0.25, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTRB(midX - w * 0.4, 0, midX + w * 0.4, h));

    // Magical Royal Edge Aura for Black pieces to guarantee crisp legibility on dark tiles
    if (!isWhite) {
      canvas.drawCircle(
        Offset(midX - w * 0.05, h * 0.55),
        w * 0.35,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0),
      );
    }

    // --- 3. Turned Lathe Foundation Geometry (Common Base Layers) ---
    // Layer A: Base Plinth
    final Path plinth = Path()
      ..moveTo(midX - w * 0.35, h * 0.84)
      ..lineTo(midX - w * 0.35, h * 0.89)
      ..quadraticBezierTo(midX, h * 0.94, midX + w * 0.35, h * 0.89)
      ..lineTo(midX + w * 0.35, h * 0.84)
      ..quadraticBezierTo(midX, h * 0.89, midX - w * 0.35, h * 0.84)
      ..close();
    drawShape(plinth, bodyPaint);

    // Layer B: Base Core Bevel
    final Path baseCore = Path()
      ..moveTo(midX - w * 0.25, h * 0.78)
      ..lineTo(midX - w * 0.33, h * 0.84)
      ..quadraticBezierTo(midX, h * 0.89, midX + w * 0.33, h * 0.84)
      ..lineTo(midX + w * 0.25, h * 0.78)
      ..quadraticBezierTo(midX, h * 0.82, midX - w * 0.25, h * 0.78)
      ..close();
    drawShape(baseCore, bodyPaint);

    // Layer C: Embedded Lower Gold Ornamental Ring
    final Path lowerGold = Path()
      ..moveTo(midX - w * 0.23, h * 0.75)
      ..lineTo(midX - w * 0.25, h * 0.78)
      ..quadraticBezierTo(midX, h * 0.82, midX + w * 0.25, h * 0.78)
      ..lineTo(midX + w * 0.23, h * 0.75)
      ..quadraticBezierTo(midX, h * 0.79, midX - w * 0.23, h * 0.75)
      ..close();
    drawShape(lowerGold, goldPaint);

    // --- 4. Fluted Central Shaft ---
    final double headBaseY = switch (type) {
      chess_lib.PieceType.KING => h * 0.35,
      chess_lib.PieceType.QUEEN => h * 0.35,
      chess_lib.PieceType.BISHOP => h * 0.40,
      chess_lib.PieceType.KNIGHT => h * 0.42,
      chess_lib.PieceType.ROOK => h * 0.45,
      _ => h * 0.50,
    };
    final double upperRingBaseY = headBaseY;
    final double upperRingTopY = headBaseY - h * 0.025;
    final double shaftTopW = switch (type) {
      chess_lib.PieceType.KING => w * 0.12,
      chess_lib.PieceType.QUEEN => w * 0.12,
      chess_lib.PieceType.BISHOP => w * 0.10,
      chess_lib.PieceType.KNIGHT => w * 0.14,
      chess_lib.PieceType.ROOK => w * 0.14,
      _ => w * 0.10,
    };

    final Path shaft = Path()
      ..moveTo(midX - shaftTopW, upperRingBaseY)
      ..cubicTo(
        midX - shaftTopW * 0.8, upperRingBaseY + h * 0.1,
        midX - w * 0.15, h * 0.65,
        midX - w * 0.22, h * 0.75,
      )
      ..quadraticBezierTo(midX, h * 0.79, midX + w * 0.22, h * 0.75)
      ..cubicTo(
        midX + w * 0.15, h * 0.65,
        midX + shaftTopW * 0.8, upperRingBaseY + h * 0.1,
        midX + shaftTopW, upperRingBaseY,
      )
      ..quadraticBezierTo(
          midX, upperRingBaseY + h * 0.03, midX - shaftTopW, upperRingBaseY)
      ..close();
    drawShape(shaft, bodyPaint);

    // Layer D: Embedded Upper Gold Ornamental Ring
    final double ringW = shaftTopW * 1.15;
    final Path upperGold = Path()
      ..moveTo(midX - ringW, upperRingTopY)
      ..lineTo(midX - ringW, upperRingBaseY)
      ..quadraticBezierTo(
          midX, upperRingBaseY + h * 0.03, midX + ringW, upperRingBaseY)
      ..lineTo(midX + ringW, upperRingTopY)
      ..quadraticBezierTo(
          midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
      ..close();
    drawShape(upperGold, goldPaint);

    // --- 5. Bespoke Highly Detailed 3D Heads ---
    final Paint thinBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black.withValues(alpha: 0.85);

    switch (type) {
      case chess_lib.PieceType.PAWN:
        final Offset center = Offset(midX, upperRingTopY - w * 0.15);
        final double radius = w * 0.15;
        // Volumetric lighting sphere
        final Paint spherePaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.8,
            colors: isWhite
                ? [
                    Colors.white,
                    const Color(0xFFE2E8F0),
                    const Color(0xFF94A3B8)
                  ]
                : [
                    const Color(0xFF475569),
                    const Color(0xFF0F172A),
                    const Color(0xFF020617)
                  ],
          ).createShader(Rect.fromCircle(center: center, radius: radius));
        canvas.drawCircle(center, radius, spherePaint);
        if (isWhite) {
          canvas.drawCircle(center, radius, thinBorderPaint);
        }

        // Specular dot
        canvas.drawCircle(
          center.translate(-radius * 0.3, -radius * 0.3),
          radius * 0.15,
          Paint()..color = Colors.white.withValues(alpha: 0.6),
        );
        break;

      case chess_lib.PieceType.ROOK:
        // Flared lower bowl
        final Path rookBowl = Path()
          ..moveTo(midX - w * 0.22, upperRingTopY - h * 0.04)
          ..lineTo(midX - ringW, upperRingTopY)
          ..quadraticBezierTo(
              midX, upperRingTopY + h * 0.03, midX + ringW, upperRingTopY)
          ..lineTo(midX + w * 0.22, upperRingTopY - h * 0.04)
          ..quadraticBezierTo(midX, upperRingTopY - h * 0.01, midX - w * 0.22,
              upperRingTopY - h * 0.04)
          ..close();
        drawShape(rookBowl, bodyPaint);

        // Dark inner hollow roof recess behind the parapet
        final Rect hollowRect = Rect.fromCenter(
            center: Offset(midX, h * 0.20), width: w * 0.44, height: h * 0.05);
        canvas.drawOval(
          hollowRect,
          Paint()
            ..color = isWhite
                ? const Color(0xFF94A3B8)
                : const Color(0xFF020617),
        );
        if (isWhite) {
          canvas.drawOval(hollowRect, thinBorderPaint);
        }

        // Overlapping Front Parapet Wall with depth cuts
        final Path frontParapet = Path()
          ..moveTo(midX - w * 0.25, h * 0.20) // Left tab outer
          ..lineTo(midX - w * 0.11, h * 0.20) // Left tab inner
          ..lineTo(midX - w * 0.11, h * 0.25) // Drop into left gap
          ..lineTo(midX - w * 0.07, h * 0.25) // Gap floor
          ..lineTo(midX - w * 0.07, h * 0.20) // Center tab left
          ..lineTo(midX + w * 0.07, h * 0.20) // Center tab right
          ..lineTo(midX + w * 0.07, h * 0.25) // Drop into right gap
          ..lineTo(midX + w * 0.11, h * 0.25) // Gap floor
          ..lineTo(midX + w * 0.11, h * 0.20) // Right tab inner
          ..lineTo(midX + w * 0.25, h * 0.20) // Right tab outer
          ..quadraticBezierTo(
              midX, upperRingTopY - h * 0.01, midX - w * 0.25, h * 0.20)
          ..close();
        drawShape(frontParapet, bodyPaint);

        // Crisp raised cap accents for the three turrets
        final Paint capPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFFACC15);
        canvas.drawLine(
            Offset(midX - w * 0.24, h * 0.20), Offset(midX - w * 0.12, h * 0.20), capPaint);
        canvas.drawLine(
            Offset(midX - w * 0.06, h * 0.20), Offset(midX + w * 0.06, h * 0.20), capPaint);
        canvas.drawLine(
            Offset(midX + w * 0.12, h * 0.20), Offset(midX + w * 0.24, h * 0.20), capPaint);
        break;

      case chess_lib.PieceType.BISHOP:
        // Main Mitre body
        final Path mitre = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..cubicTo(
            midX - w * 0.22, upperRingTopY - h * 0.08,
            midX - w * 0.15, h * 0.20,
            midX, h * 0.16,
          )
          ..cubicTo(
            midX + w * 0.15, h * 0.20,
            midX + w * 0.22, upperRingTopY - h * 0.08,
            midX + ringW, upperRingTopY,
          )
          ..quadraticBezierTo(
              midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawShape(mitre, bodyPaint);

        // Deep cross-cut central slash revealing dark internal volume
        final Path cutPath = Path()
          ..moveTo(midX + w * 0.05, h * 0.18)
          ..quadraticBezierTo(
              midX - w * 0.05, h * 0.24, midX - w * 0.08, h * 0.30)
          ..quadraticBezierTo(
              midX - w * 0.02, h * 0.25, midX + w * 0.08, h * 0.20)
          ..close();
        canvas.drawPath(
          cutPath,
          Paint()
            ..color = isWhite
                ? const Color(0xFF94A3B8)
                : const Color(0xFF020617),
        );
        if (isWhite) {
          canvas.drawPath(cutPath, thinBorderPaint);
        }

        // Wrapping gold horizontal band
        final Path mitreBand = Path()
          ..moveTo(midX - w * 0.16, h * 0.31)
          ..quadraticBezierTo(midX, h * 0.34, midX + w * 0.16, h * 0.31)
          ..lineTo(midX + w * 0.15, h * 0.28)
          ..quadraticBezierTo(midX, h * 0.31, midX - w * 0.15, h * 0.28)
          ..close();
        drawShape(mitreBand, goldPaint);

        // Crowning finial pearl
        canvas.drawCircle(Offset(midX, h * 0.13), w * 0.035, goldPaint);
        if (isWhite) {
          canvas.drawCircle(Offset(midX, h * 0.13), w * 0.035, thinBorderPaint);
        }
        canvas.drawCircle(Offset(midX - 1, h * 0.13 - 1), w * 0.01,
            Paint()..color = Colors.white);
        break;

      case chess_lib.PieceType.QUEEN:
        // Shadowed Inner rear tiara wall
        final Path backCrown = Path()
          ..moveTo(midX - w * 0.25, h * 0.22)
          ..quadraticBezierTo(midX, h * 0.25, midX + w * 0.25, h * 0.22)
          ..lineTo(midX, upperRingTopY)
          ..close();
        canvas.drawPath(
          backCrown,
          Paint()
            ..color = isWhite
                ? const Color(0xFF94A3B8)
                : const Color(0xFF020617),
        );
        if (isWhite) {
          canvas.drawPath(backCrown, thinBorderPaint);
        }

        // Front layered tiara wall stretching gracefully to 5 sharp peaks
        final Path frontCrown = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..lineTo(midX - w * 0.28, h * 0.18) // Far left peak
          ..quadraticBezierTo(
              midX - w * 0.21, h * 0.23, midX - w * 0.15, h * 0.15) // Mid left
          ..quadraticBezierTo(
              midX - w * 0.07, h * 0.21, midX, h * 0.13) // Center peak
          ..quadraticBezierTo(
              midX + w * 0.07, h * 0.21, midX + w * 0.15, h * 0.15) // Mid right
          ..quadraticBezierTo(
              midX + w * 0.21, h * 0.23, midX + w * 0.28, h * 0.18) // Far right
          ..lineTo(midX + ringW, upperRingTopY)
          ..quadraticBezierTo(
              midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawShape(frontCrown, bodyPaint);

        // Studded crowning pearls at all 5 tiara peaks
        final List<Offset> peaks = [
          Offset(midX - w * 0.28, h * 0.18),
          Offset(midX - w * 0.15, h * 0.15),
          Offset(midX, h * 0.13),
          Offset(midX + w * 0.15, h * 0.15),
          Offset(midX + w * 0.28, h * 0.18),
        ];
        for (final peak in peaks) {
          canvas.drawCircle(peak, w * 0.028, goldPaint);
          if (isWhite) {
            canvas.drawCircle(peak, w * 0.028, thinBorderPaint);
          }
          canvas.drawCircle(
              peak.translate(-0.5, -0.5), w * 0.008, Paint()..color = Colors.white);
        }
        break;

      case chess_lib.PieceType.KING:
        // Base crown cup flaring outward
        final Path kingBowl = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..cubicTo(
            midX - w * 0.28, upperRingTopY - h * 0.02,
            midX - w * 0.28, h * 0.28,
            midX - w * 0.22, h * 0.24,
          )
          ..lineTo(midX + w * 0.22, h * 0.24)
          ..cubicTo(
            midX + w * 0.28, h * 0.28,
            midX + w * 0.28, upperRingTopY - h * 0.02,
            midX + ringW, upperRingTopY,
          )
          ..quadraticBezierTo(
              midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawShape(kingBowl, bodyPaint);

        // Embellished Gold Crown Rim Band
        final Path kingRim = Path()
          ..moveTo(midX - w * 0.23, h * 0.24)
          ..lineTo(midX - w * 0.24, h * 0.21)
          ..quadraticBezierTo(midX, h * 0.23, midX + w * 0.24, h * 0.21)
          ..lineTo(midX + w * 0.23, h * 0.24)
          ..quadraticBezierTo(midX, h * 0.26, midX - w * 0.23, h * 0.24)
          ..close();
        drawShape(kingRim, goldPaint);

        // 3D Prominently Beveled Pattee Cross Finial
        final double cx = midX;
        final double cy = h * 0.13;
        final double armL = w * 0.07;
        final double ww = w * 0.055;
        final double cw = w * 0.015;

        final Path crossPath = Path()
          ..moveTo(cx - ww, cy - armL)
          ..lineTo(cx + ww, cy - armL)
          ..lineTo(cx + cw, cy - cw)
          ..lineTo(cx + armL, cy - ww)
          ..lineTo(cx + armL, cy + ww)
          ..lineTo(cx + cw, cy + cw)
          ..lineTo(cx + ww, cy + armL)
          ..lineTo(cx - ww, cy + armL)
          ..lineTo(cx - cw, cy + cw)
          ..lineTo(cx - armL, cy + ww)
          ..lineTo(cx - armL, cy - ww)
          ..lineTo(cx - cw, cy - cw)
          ..close();
        drawShape(crossPath, goldPaint);

        // Inner beveled ridge lines giving structural cast depth
        final Paint bevelPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withValues(alpha: 0.7);
        canvas.drawLine(Offset(cx - armL, cy), Offset(cx + armL, cy), bevelPaint);
        canvas.drawLine(Offset(cx, cy - armL), Offset(cx, cy + armL), bevelPaint);
        break;

      case chess_lib.PieceType.KNIGHT:
        // Sculptural masterpiece of overlapping multi-layered facial topology
        // Layer 1: Background far ear
        final Path farEar = Path()
          ..moveTo(midX + w * 0.05, h * 0.25)
          ..lineTo(midX + w * 0.12, h * 0.16)
          ..lineTo(midX + w * 0.16, h * 0.22)
          ..close();
        canvas.drawPath(
          farEar,
          Paint()
            ..color = isWhite
                ? const Color(0xFF94A3B8)
                : const Color(0xFF020617),
        );
        if (isWhite) {
          canvas.drawPath(farEar, thinBorderPaint);
        }

        // Layer 2: Sweeping, separated flowing locks of the golden royal mane
        final Path mane = Path()
          ..moveTo(midX + w * 0.12, h * 0.22)
          ..quadraticBezierTo(
              midX + w * 0.28, h * 0.28, midX + w * 0.32, h * 0.35) // Lock 1
          ..lineTo(midX + w * 0.22, h * 0.35)
          ..quadraticBezierTo(
              midX + w * 0.32, h * 0.42, midX + w * 0.34, h * 0.48) // Lock 2
          ..lineTo(midX + w * 0.24, h * 0.48)
          ..quadraticBezierTo(
              midX + w * 0.30, h * 0.58, midX + w * 0.28, h * 0.65) // Lock 3
          ..lineTo(midX + ringW, upperRingTopY)
          ..lineTo(midX, upperRingTopY)
          ..close();
        drawShape(mane, goldPaint);

        // Layer 3: Main muscular head and thick neck block
        final Path horseHead = Path()
          ..moveTo(midX - ringW, upperRingTopY) // Chest front
          ..cubicTo(
            midX - w * 0.28, h * 0.58,
            midX - w * 0.32, h * 0.42,
            midX - w * 0.30, h * 0.32,
          ) // Sweeping robust chest up to snout
          ..quadraticBezierTo(
              midX - w * 0.25, h * 0.25, midX - w * 0.15, h * 0.24) // Snout bridge
          ..lineTo(midX + w * 0.05, h * 0.20) // Forehead slope
          ..lineTo(midX + w * 0.18, h * 0.28) // Rear crown
          ..cubicTo(
            midX + w * 0.18, h * 0.45,
            midX + w * 0.10, h * 0.60,
            midX + ringW, upperRingTopY,
          ) // Inner rear neck curve
          ..quadraticBezierTo(
              midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawShape(horseHead, bodyPaint);

        // Layer 4: Raised contoured cheekbone/jawplate overlay to define pure 3D anatomy
        final Path cheek = Path()
          ..moveTo(midX - w * 0.10, h * 0.32)
          ..quadraticBezierTo(
              midX + w * 0.05, h * 0.30, midX + w * 0.08, h * 0.42)
          ..quadraticBezierTo(midX, h * 0.52, midX - w * 0.12, h * 0.45)
          ..close();
        drawShape(
          cheek,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isWhite
                  ? [Colors.white, const Color(0xFFF1F5F9)]
                  : [const Color(0xFF475569), const Color(0xFF1E293B)],
            ).createShader(cheek.getBounds()),
        );

        // Layer 5: Foreground near ear
        final Path nearEar = Path()
          ..moveTo(midX, h * 0.22)
          ..lineTo(midX + w * 0.06, h * 0.12)
          ..lineTo(midX + w * 0.12, h * 0.20)
          ..close();
        drawShape(nearEar, bodyPaint);
        canvas.drawPath(
          nearEar,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0
            ..color = const Color(0xFFCA8A04),
        );

        // Layer 6: Recessed Eye Socket & Radiant Embedded Eye Bead
        final Offset eyeCenter = Offset(midX - w * 0.08, h * 0.28);
        canvas.drawOval(
          Rect.fromCenter(
              center: eyeCenter, width: w * 0.05, height: w * 0.035),
          Paint()..color = Colors.black.withValues(alpha: 0.5),
        );
        canvas.drawCircle(
          eyeCenter,
          w * 0.015,
          Paint()
            ..color = isWhite
                ? const Color(0xFFCA8A04)
                : const Color(0xFF38BDF8),
        );
        canvas.drawCircle(
          eyeCenter.translate(-0.5, -0.5),
          w * 0.005,
          Paint()..color = Colors.white,
        );

        // Layer 7: Carved Nostril Curve
        canvas.drawArc(
          Rect.fromCenter(
              center: Offset(midX - w * 0.24, h * 0.29),
              width: w * 0.035,
              height: w * 0.02),
          0,
          pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.black.withValues(alpha: 0.4),
        );
        break;
    }

    // --- 6. Polished High-Gloss Sheen (Crisp Left Edge Specular Profile) ---
    final Paint rimHighlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = isWhite
          ? Colors.white.withValues(alpha: 0.9)
          : const Color(0xFF7DD3FC).withValues(alpha: 0.8);

    final Path leftRim = Path()
      ..moveTo(midX - w * 0.33, h * 0.86)
      ..lineTo(midX - w * 0.23, h * 0.76)
      ..lineTo(midX - shaftTopW * 0.95, upperRingBaseY);
    canvas.drawPath(leftRim, rimHighlightPaint);
  }

  @override
  bool shouldRepaint(RoyalVectorPiecePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.isWhite != isWhite ||
      oldDelegate.isHighlighted != isHighlighted ||
      oldDelegate.animationValue != animationValue;
}

/// Renders the custom premium 3D pedestal selection ring spinning directly on the tile floor.
class RoyalSelectionPainter extends CustomPainter {
  final double animationValue;

  RoyalSelectionPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Precisely matched to average piece base foundation level
    final Offset center = Offset(w / 2, h * 0.865);
    final double radius = w * 0.42;

    // 1. External Magical Ground Aura
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: radius * 2.2, height: radius * 0.75),
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
    );

    // 2. Uplight Radiance emanating upwards onto piece plinths
    canvas.drawOval(
      Rect.fromCenter(
          center: center, width: radius * 2.0, height: radius * 0.66),
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFACC15).withValues(alpha: 0.5),
            const Color(0xFFEAB308).withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // 3. Dynamic Spinning 3D Perspective Isometric Rings
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.0, 0.33); // Isometrically flatten circle into floor plane

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFACC15);

    final Paint cyanRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF7DD3FC);

    final double angle = animationValue * 2 * pi;

    // Dual orbiting main golden bounding segments
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      angle,
      pi / 2,
      false,
      ringPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      angle + pi,
      pi / 2,
      false,
      ringPaint,
    );

    // Counter-rotating inner cyan focus indicator arcs
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.85),
      -angle * 1.5,
      pi / 3,
      false,
      cyanRingPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: radius * 0.85),
      -angle * 1.5 + pi,
      pi / 3,
      false,
      cyanRingPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(RoyalSelectionPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
