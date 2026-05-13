import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

/// Premium high-fidelity programmatic vector painter for Walnut Wood Theme pieces.
/// Masterfully captures hand-carved Boxwood/Maple and deep Walnut textures with a soft,
/// natural satin/matte finish. Features precise Staunton proportions, embedded accent inlays,
/// occlusion shading, and robust outlines to ensure perfect visibility across all squares.
class WalnutPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;

  WalnutPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    // --- 1. Satin/Matte Natural Wood Shaders ---
    // Primary Body Material (Soft gradients mimicking unvarnished satin wood grain depth)
    final Paint bodyFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isWhite
            ? const [
                Color(0xFFFFFDF0), // Ivory Cream Top
                Color(0xFFF3E5AB), // Natural Warm Maple
                Color(0xFFD6BA8B), // Aged Maple Falloff
              ]
            : const [
                Color(0xFF7A5230), // Warm Medium Walnut
                Color(0xFF52331C), // Deep Chocolate Wood
                Color(0xFF331D0E), // Espresso Core Bottom
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    // Embedded Inlay Accent Material (Contrasting wood types for luxury detailing)
    final Paint inlayFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isWhite
            ? const [
                Color(0xFF3E2723), // Dark Ebony Inlay for White pieces
                Color(0xFF1B0000),
              ]
            : const [
                Color(0xFFFFF8E1), // Soft Boxwood Inlay for Black pieces
                Color(0xFFFFE082),
              ],
      ).createShader(Rect.fromLTRB(midX - w * 0.3, 0, midX + w * 0.3, h));

    // Internal Shadow / Recess Fill
    final Paint recessFill = Paint()
      ..style = PaintingStyle.fill
      ..color = isWhite
          ? const Color(0xFFBCAAA4).withValues(alpha: 0.8)
          : const Color(0xFF1E0B00).withValues(alpha: 0.95);

    // Pristine Exterior Outline ensuring distinct legibility against all board squares
    final Paint borderStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = isWhite
          ? Colors.black.withValues(alpha: 0.85)
          : Colors.black.withValues(alpha: 0.95);

    // Helper method to draw solid shapes with crisp outlining
    void drawCarvedLayer(Path path, Paint fillPaint) {
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderStroke);
    }

    // --- 2. Perspective Soft Drop Shadow ---
    final Path shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(midX + w * 0.03, h * 0.88),
        width: w * 0.72,
        height: h * 0.14,
      ));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
    );

    // Optional highlight glow if selected
    if (isHighlighted) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(midX, h * 0.86), width: w * 0.85, height: h * 0.25),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0),
      );
    }

    // --- 3. Turned Lathe Base Geometry (Shared Foundation Layers) ---
    // Layer A: Wide Foot Plinth
    final Path footPlinth = Path()
      ..moveTo(midX - w * 0.35, h * 0.83)
      ..lineTo(midX - w * 0.35, h * 0.88)
      ..quadraticBezierTo(midX, h * 0.93, midX + w * 0.35, h * 0.88)
      ..lineTo(midX + w * 0.35, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX - w * 0.35, h * 0.83)
      ..close();
    drawCarvedLayer(footPlinth, bodyFill);

    // Layer B: Base Core Bevel Step
    final Path baseBevel = Path()
      ..moveTo(midX - w * 0.26, h * 0.77)
      ..lineTo(midX - w * 0.33, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX + w * 0.33, h * 0.83)
      ..lineTo(midX + w * 0.26, h * 0.77)
      ..quadraticBezierTo(midX, h * 0.81, midX - w * 0.26, h * 0.77)
      ..close();
    drawCarvedLayer(baseBevel, bodyFill);

    // Layer C: Embedded Contrasting Inlay Base Ring
    final Path lowerInlay = Path()
      ..moveTo(midX - w * 0.24, h * 0.74)
      ..lineTo(midX - w * 0.26, h * 0.77)
      ..quadraticBezierTo(midX, h * 0.81, midX + w * 0.26, h * 0.77)
      ..lineTo(midX + w * 0.24, h * 0.74)
      ..quadraticBezierTo(midX, h * 0.78, midX - w * 0.24, h * 0.74)
      ..close();
    drawCarvedLayer(lowerInlay, inlayFill);

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

    final Path centralShaft = Path()
      ..moveTo(midX - shaftTopW, upperRingBaseY)
      ..cubicTo(
        midX - shaftTopW * 0.8, upperRingBaseY + h * 0.1,
        midX - w * 0.15, h * 0.65,
        midX - w * 0.22, h * 0.74,
      )
      ..quadraticBezierTo(midX, h * 0.78, midX + w * 0.22, h * 0.74)
      ..cubicTo(
        midX + w * 0.15, h * 0.65,
        midX + shaftTopW * 0.8, upperRingBaseY + h * 0.1,
        midX + shaftTopW, upperRingBaseY,
      )
      ..quadraticBezierTo(midX, upperRingBaseY + h * 0.03, midX - shaftTopW, upperRingBaseY)
      ..close();
    drawCarvedLayer(centralShaft, bodyFill);

    // Layer D: Upper Collar Inlay Ring
    final double ringW = shaftTopW * 1.15;
    final Path upperInlay = Path()
      ..moveTo(midX - ringW, upperRingTopY)
      ..lineTo(midX - ringW, upperRingBaseY)
      ..quadraticBezierTo(midX, upperRingBaseY + h * 0.03, midX + ringW, upperRingBaseY)
      ..lineTo(midX + ringW, upperRingTopY)
      ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
      ..close();
    drawCarvedLayer(upperInlay, inlayFill);

    // --- 5. Bespoke Premium Hand-Carved Heads ---
    switch (type) {
      case chess_lib.PieceType.PAWN:
        final Offset sphereCenter = Offset(midX, upperRingTopY - w * 0.15);
        final double radius = w * 0.15;
        
        // Soft radial shader to map perfect wooden sphere curvature without high gloss
        final Paint spherePaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.9,
            colors: isWhite
                ? const [Color(0xFFFFFDF0), Color(0xFFEADB95), Color(0xFFC7A973)]
                : const [Color(0xFF8D613C), Color(0xFF52331C), Color(0xFF2B1A0E)],
          ).createShader(Rect.fromCircle(center: sphereCenter, radius: radius));
        
        canvas.drawCircle(sphereCenter, radius, spherePaint);
        canvas.drawCircle(sphereCenter, radius, borderStroke);
        break;

      case chess_lib.PieceType.ROOK:
        // Lower flared supporting bowl
        final Path rookBowl = Path()
          ..moveTo(midX - w * 0.22, upperRingTopY - h * 0.04)
          ..lineTo(midX - ringW, upperRingTopY)
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX + ringW, upperRingTopY)
          ..lineTo(midX + w * 0.22, upperRingTopY - h * 0.04)
          ..quadraticBezierTo(midX, upperRingTopY - h * 0.01, midX - w * 0.22, upperRingTopY - h * 0.04)
          ..close();
        drawCarvedLayer(rookBowl, bodyFill);

        // Volumetric hollow inner roof recess
        final Rect roofRecess = Rect.fromCenter(
          center: Offset(midX, h * 0.20),
          width: w * 0.44,
          height: h * 0.05,
        );
        canvas.drawOval(roofRecess, recessFill);
        canvas.drawOval(roofRecess, borderStroke);

        // Front layered Battlement wall showcasing prominent clean crenellations
        final Path parapet = Path()
          ..moveTo(midX - w * 0.25, h * 0.20) // Left tab outer
          ..lineTo(midX - w * 0.11, h * 0.20) // Left tab inner
          ..lineTo(midX - w * 0.11, h * 0.26) // Drop down into left gap
          ..lineTo(midX - w * 0.07, h * 0.26) // Gap base
          ..lineTo(midX - w * 0.07, h * 0.20) // Center tab left
          ..lineTo(midX + w * 0.07, h * 0.20) // Center tab right
          ..lineTo(midX + w * 0.07, h * 0.26) // Drop down into right gap
          ..lineTo(midX + w * 0.11, h * 0.26) // Gap base
          ..lineTo(midX + w * 0.11, h * 0.20) // Right tab inner
          ..lineTo(midX + w * 0.25, h * 0.20) // Right tab outer
          ..quadraticBezierTo(midX, upperRingTopY - h * 0.01, midX - w * 0.25, h * 0.20)
          ..close();
        drawCarvedLayer(parapet, bodyFill);
        break;

      case chess_lib.PieceType.BISHOP:
        // Traditional Mitre Body Oval
        final Path mitreHead = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..cubicTo(
            midX - w * 0.22, upperRingTopY - h * 0.08,
            midX - w * 0.16, h * 0.20,
            midX, h * 0.16,
          )
          ..cubicTo(
            midX + w * 0.16, h * 0.20,
            midX + w * 0.22, upperRingTopY - h * 0.08,
            midX + ringW, upperRingTopY,
          )
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawCarvedLayer(mitreHead, bodyFill);

        // Deep central diagonal cleft / Miter slash
        final Path cleft = Path()
          ..moveTo(midX + w * 0.05, h * 0.18)
          ..quadraticBezierTo(midX - w * 0.05, h * 0.24, midX - w * 0.08, h * 0.32)
          ..quadraticBezierTo(midX - w * 0.02, h * 0.26, midX + w * 0.08, h * 0.20)
          ..close();
        canvas.drawPath(cleft, recessFill);
        canvas.drawPath(cleft, borderStroke);

        // Crowning finial sphere
        final Offset pearlPos = Offset(midX, h * 0.12);
        canvas.drawCircle(pearlPos, w * 0.035, bodyFill);
        canvas.drawCircle(pearlPos, w * 0.035, borderStroke);
        break;

      case chess_lib.PieceType.QUEEN:
        // Rear inner tiara wall background
        final Path rearTiara = Path()
          ..moveTo(midX - w * 0.25, h * 0.22)
          ..quadraticBezierTo(midX, h * 0.25, midX + w * 0.25, h * 0.22)
          ..lineTo(midX, upperRingTopY)
          ..close();
        canvas.drawPath(rearTiara, recessFill);
        canvas.drawPath(rearTiara, borderStroke);

        // Expanding frontal tiara robes forming 5 masterfully sculpted points
        final Path frontTiara = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..lineTo(midX - w * 0.28, h * 0.18) // Far left peak
          ..quadraticBezierTo(midX - w * 0.21, h * 0.23, midX - w * 0.15, h * 0.15) // Mid left
          ..quadraticBezierTo(midX - w * 0.07, h * 0.21, midX, h * 0.13) // Center peak
          ..quadraticBezierTo(midX + w * 0.07, h * 0.21, midX + w * 0.15, h * 0.15) // Mid right
          ..quadraticBezierTo(midX + w * 0.21, h * 0.23, midX + w * 0.28, h * 0.18) // Far right
          ..lineTo(midX + ringW, upperRingTopY)
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawCarvedLayer(frontTiara, bodyFill);

        // Crowning accent inlay pearls on all 5 tiara peaks
        final List<Offset> qPeaks = [
          Offset(midX - w * 0.28, h * 0.18),
          Offset(midX - w * 0.15, h * 0.15),
          Offset(midX, h * 0.13),
          Offset(midX + w * 0.15, h * 0.15),
          Offset(midX + w * 0.28, h * 0.18),
        ];
        for (final pt in qPeaks) {
          canvas.drawCircle(pt, w * 0.026, inlayFill);
          canvas.drawCircle(pt, w * 0.026, borderStroke);
        }
        break;

      case chess_lib.PieceType.KING:
        // Wide flaring royal lower crown base bowl
        final Path kBowl = Path()
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
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawCarvedLayer(kBowl, bodyFill);

        // Prominent contrasting upper crown inlay band
        final Path kBand = Path()
          ..moveTo(midX - w * 0.23, h * 0.24)
          ..lineTo(midX - w * 0.24, h * 0.21)
          ..quadraticBezierTo(midX, h * 0.23, midX + w * 0.24, h * 0.21)
          ..lineTo(midX + w * 0.23, h * 0.24)
          ..quadraticBezierTo(midX, h * 0.26, midX - w * 0.23, h * 0.24)
          ..close();
        drawCarvedLayer(kBand, inlayFill);

        // Stately 3D Beveled Pattee Cross Finial
        final double cx = midX;
        final double cy = h * 0.13;
        final double arm = w * 0.07;
        final double endW = w * 0.055;
        final double coreW = w * 0.015;

        final Path cross = Path()
          ..moveTo(cx - endW, cy - arm)
          ..lineTo(cx + endW, cy - arm)
          ..lineTo(cx + coreW, cy - coreW)
          ..lineTo(cx + arm, cy - endW)
          ..lineTo(cx + arm, cy + endW)
          ..lineTo(cx + coreW, cy + coreW)
          ..lineTo(cx + endW, cy + arm)
          ..lineTo(cx - endW, cy + arm)
          ..lineTo(cx - coreW, cy + coreW)
          ..lineTo(cx - arm, cy + endW)
          ..lineTo(cx - arm, cy - endW)
          ..lineTo(cx - coreW, cy - coreW)
          ..close();
        drawCarvedLayer(cross, bodyFill);

        // Subtle internal bevel ridge cuts for material authenticity
        final Paint bevelLine = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = borderStroke.color.withValues(alpha: 0.3);
        canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), bevelLine);
        canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), bevelLine);
        break;

      case chess_lib.PieceType.KNIGHT:
        // Sculptural masterpiece of organic wooden horsehead anatomy
        // Layer 1: Background far ear
        final Path farEar = Path()
          ..moveTo(midX + w * 0.05, h * 0.25)
          ..lineTo(midX + w * 0.12, h * 0.16)
          ..lineTo(midX + w * 0.16, h * 0.22)
          ..close();
        canvas.drawPath(farEar, recessFill);
        canvas.drawPath(farEar, borderStroke);

        // Layer 2: Contrasting Inlay Mane Locks cascading down the rear crest
        final Path maneLocks = Path()
          ..moveTo(midX + w * 0.12, h * 0.22)
          ..quadraticBezierTo(midX + w * 0.28, h * 0.28, midX + w * 0.32, h * 0.35)
          ..lineTo(midX + w * 0.22, h * 0.35)
          ..quadraticBezierTo(midX + w * 0.32, h * 0.42, midX + w * 0.34, h * 0.48)
          ..lineTo(midX + w * 0.24, h * 0.48)
          ..quadraticBezierTo(midX + w * 0.30, h * 0.58, midX + w * 0.28, h * 0.65)
          ..lineTo(midX + ringW, upperRingTopY)
          ..lineTo(midX, upperRingTopY)
          ..close();
        drawCarvedLayer(maneLocks, inlayFill);

        // Layer 3: Main muscular stallion head block
        final Path stallionHead = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..cubicTo(
            midX - w * 0.28, h * 0.58,
            midX - w * 0.32, h * 0.42,
            midX - w * 0.30, h * 0.32,
          ) // Sweeping full chest profile up to snout
          ..quadraticBezierTo(midX - w * 0.25, h * 0.25, midX - w * 0.15, h * 0.24) // Snout bridge
          ..lineTo(midX + w * 0.05, h * 0.20) // Forehead slope
          ..lineTo(midX + w * 0.18, h * 0.28) // Rear crown junction
          ..cubicTo(
            midX + w * 0.18, h * 0.45,
            midX + w * 0.10, h * 0.60,
            midX + ringW, upperRingTopY,
          )
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();
        drawCarvedLayer(stallionHead, bodyFill);

        // Layer 4: Raised Contoured Cheekbone overlay plate
        final Path cheekbone = Path()
          ..moveTo(midX - w * 0.10, h * 0.32)
          ..quadraticBezierTo(midX + w * 0.05, h * 0.30, midX + w * 0.08, h * 0.42)
          ..quadraticBezierTo(midX, h * 0.52, midX - w * 0.12, h * 0.45)
          ..close();
        drawCarvedLayer(cheekbone, bodyFill);

        // Layer 5: Near Foreground Ear
        final Path nearEar = Path()
          ..moveTo(midX, h * 0.22)
          ..lineTo(midX + w * 0.06, h * 0.12)
          ..lineTo(midX + w * 0.12, h * 0.20)
          ..close();
        drawCarvedLayer(nearEar, bodyFill);

        // Layer 6: Deep Carved Eye Socket & Radiant Wood Bead Eye
        final Offset eyePos = Offset(midX - w * 0.08, h * 0.28);
        canvas.drawOval(
          Rect.fromCenter(center: eyePos, width: w * 0.05, height: w * 0.035),
          recessFill,
        );
        canvas.drawCircle(eyePos, w * 0.015, inlayFill);
        canvas.drawCircle(eyePos, w * 0.015, borderStroke);

        // Layer 7: Distinct Carved Nostril Slit
        canvas.drawArc(
          Rect.fromCenter(center: Offset(midX - w * 0.24, h * 0.29), width: w * 0.035, height: w * 0.02),
          0,
          pi,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = borderStroke.color.withValues(alpha: 0.6),
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant WalnutPiecePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.isWhite != isWhite ||
      oldDelegate.isHighlighted != isHighlighted;
}
