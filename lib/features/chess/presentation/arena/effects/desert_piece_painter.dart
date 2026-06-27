import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

class DesertPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;

  DesertPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    // --- 1. Gradients and Paints ---
    // Body material (Warm sandstone cream vs deep terracotta clay)
    final Paint bodyFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isWhite
            ? const [
                Color(0xFFFAF9F6), // Pure white sand / alabaster
                Color(0xFFF7E9C8), // Warm desert sand
                Color(0xFFDCC89E), // Sandy ochre falloff
              ]
            : const [
                Color(0xFFB46A42), // Rich light terracotta clay
                Color(0xFF8C4C2B), // Deep desert clay
                Color(0xFF5E3017), // Terracotta shadow core
              ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(midX - w * 0.35, 0, midX + w * 0.35, h));

    // Contrast Inlays (contrasting accents)
    final Paint inlayFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: isWhite
            ? const [Color(0xFF8C4C2B), Color(0xFF5E3017)] // Terracotta inlay for white pieces
            : const [Color(0xFFFAF9F6), Color(0xFFF7E9C8)], // Sand inlay for dark pieces
      ).createShader(Rect.fromLTRB(midX - w * 0.2, 0, midX + w * 0.2, h));

    // Internal Shadow/Recess Fill (for non-hole carvings)
    final Paint recessFill = Paint()
      ..style = PaintingStyle.fill
      ..color = isWhite
          ? const Color(0xFFD7CCC8).withValues(alpha: 0.8)
          : const Color(0xFF3E2723).withValues(alpha: 0.85);

    // Border outline for high contrast
    final Paint borderStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.9);

    void drawCarvedLayer(Path path, Paint fillPaint) {
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderStroke);
    }

    // --- 2. Perspective Drop Shadow ---
    final Path shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(midX, h * 0.88),
        width: w * 0.72,
        height: h * 0.12,
      ));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // Selected glow
    if (isHighlighted) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(midX, h * 0.86), width: w * 0.85, height: h * 0.22),
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
      );
    }

    // --- 3. Lathe Base Geometry (Shared Layers) ---
    // Foot Plinth
    final Path footPlinth = Path()
      ..moveTo(midX - w * 0.35, h * 0.83)
      ..lineTo(midX - w * 0.35, h * 0.88)
      ..quadraticBezierTo(midX, h * 0.93, midX + w * 0.35, h * 0.88)
      ..lineTo(midX + w * 0.35, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX - w * 0.35, h * 0.83)
      ..close();
    drawCarvedLayer(footPlinth, bodyFill);

    // Base core bevel
    final Path baseBevel = Path()
      ..moveTo(midX - w * 0.27, h * 0.77)
      ..lineTo(midX - w * 0.33, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX + w * 0.33, h * 0.83)
      ..lineTo(midX + w * 0.27, h * 0.77)
      ..quadraticBezierTo(midX, h * 0.81, midX - w * 0.27, h * 0.77)
      ..close();
    drawCarvedLayer(baseBevel, bodyFill);

    // Lower Inlay Ring
    final Path lowerInlay = Path()
      ..moveTo(midX - w * 0.25, h * 0.74)
      ..lineTo(midX - w * 0.27, h * 0.77)
      ..quadraticBezierTo(midX, h * 0.81, midX + w * 0.27, h * 0.77)
      ..lineTo(midX + w * 0.25, h * 0.74)
      ..quadraticBezierTo(midX, h * 0.78, midX - w * 0.25, h * 0.74)
      ..close();
    drawCarvedLayer(lowerInlay, inlayFill);

    // --- 4. Central Shaft with Negative Space Cutouts ---
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

    Path centralShaft = Path()
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

    // Inject negative space cutout (hole) in the center of the shaft
    if (type == chess_lib.PieceType.PAWN) {
      final Path pawnHole = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(midX, h * 0.62),
          width: w * 0.12,
          height: h * 0.08,
        ));
      centralShaft = Path.combine(PathOperation.difference, centralShaft, pawnHole);
    } else if (type == chess_lib.PieceType.ROOK) {
      final Path rookHole = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(midX, h * 0.60), width: w * 0.09, height: h * 0.14),
          const Radius.circular(4.0),
        ));
      centralShaft = Path.combine(PathOperation.difference, centralShaft, rookHole);
    } else if (type == chess_lib.PieceType.QUEEN) {
      final Path queenHole = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(midX, h * 0.58),
          width: w * 0.08,
          height: h * 0.10,
        ));
      centralShaft = Path.combine(PathOperation.difference, centralShaft, queenHole);
    }

    drawCarvedLayer(centralShaft, bodyFill);

    // Upper collar inlay ring
    final double ringW = shaftTopW * 1.15;
    final Path upperInlay = Path()
      ..moveTo(midX - ringW, upperRingTopY)
      ..lineTo(midX - ringW, upperRingBaseY)
      ..quadraticBezierTo(midX, upperRingBaseY + h * 0.03, midX + ringW, upperRingBaseY)
      ..lineTo(midX + ringW, upperRingTopY)
      ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
      ..close();
    drawCarvedLayer(upperInlay, inlayFill);

    // --- 5. Bespoke Heads with Sand Grain Cutouts ---
    switch (type) {
      case chess_lib.PieceType.PAWN:
        final Offset sphereCenter = Offset(midX, upperRingTopY - w * 0.15);
        final double radius = w * 0.15;
        
        final Paint spherePaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.2, -0.2),
            radius: 0.9,
            colors: isWhite
                ? const [Color(0xFFFAF9F6), Color(0xFFF7E9C8), Color(0xFFDCC89E)]
                : const [Color(0xFFB46A42), Color(0xFF8C4C2B), Color(0xFF5E3017)],
          ).createShader(Rect.fromCircle(center: sphereCenter, radius: radius));

        // Pawn head circular hole
        Path headPath = Path()..addOval(Rect.fromCircle(center: sphereCenter, radius: radius));
        final Path headHole = Path()
          ..addOval(Rect.fromCircle(center: sphereCenter, radius: radius * 0.35));
        headPath = Path.combine(PathOperation.difference, headPath, headHole);

        drawCarvedLayer(headPath, spherePaint);
        break;

      case chess_lib.PieceType.ROOK:
        final Path rookBowl = Path()
          ..moveTo(midX - w * 0.22, upperRingTopY - h * 0.04)
          ..lineTo(midX - ringW, upperRingTopY)
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX + ringW, upperRingTopY)
          ..lineTo(midX + w * 0.22, upperRingTopY - h * 0.04)
          ..quadraticBezierTo(midX, upperRingTopY - h * 0.01, midX - w * 0.22, upperRingTopY - h * 0.04)
          ..close();
        drawCarvedLayer(rookBowl, bodyFill);

        final Rect roofRecess = Rect.fromCenter(
          center: Offset(midX, h * 0.20),
          width: w * 0.44,
          height: h * 0.05,
        );
        canvas.drawOval(roofRecess, recessFill);
        canvas.drawOval(roofRecess, borderStroke);

        Path parapet = Path()
          ..moveTo(midX - w * 0.25, h * 0.20)
          ..lineTo(midX - w * 0.11, h * 0.20)
          ..lineTo(midX - w * 0.11, h * 0.26)
          ..lineTo(midX - w * 0.07, h * 0.26)
          ..lineTo(midX - w * 0.07, h * 0.20)
          ..lineTo(midX + w * 0.07, h * 0.20)
          ..lineTo(midX + w * 0.07, h * 0.26)
          ..lineTo(midX + w * 0.11, h * 0.26)
          ..lineTo(midX + w * 0.11, h * 0.20)
          ..lineTo(midX + w * 0.25, h * 0.20)
          ..quadraticBezierTo(midX, upperRingTopY - h * 0.01, midX - w * 0.25, h * 0.20)
          ..close();
        
        // Circular hole in battlements base
        final Path battlementHole = Path()
          ..addOval(Rect.fromCircle(center: Offset(midX, h * 0.32), radius: w * 0.05));
        parapet = Path.combine(PathOperation.difference, parapet, battlementHole);

        drawCarvedLayer(parapet, bodyFill);
        break;

      case chess_lib.PieceType.BISHOP:
        Path mitreHead = Path()
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

        // Diagonal cleft slot cutout
        final Path cleftHole = Path()
          ..moveTo(midX + w * 0.03, h * 0.19)
          ..quadraticBezierTo(midX - w * 0.05, h * 0.24, midX - w * 0.08, h * 0.31)
          ..quadraticBezierTo(midX - w * 0.02, h * 0.26, midX + w * 0.06, h * 0.21)
          ..close();
        
        // Circular drop hole below cleft
        final Path dropHole = Path()
          ..addOval(Rect.fromCircle(center: Offset(midX, h * 0.28), radius: w * 0.045));

        mitreHead = Path.combine(PathOperation.difference, mitreHead, cleftHole);
        mitreHead = Path.combine(PathOperation.difference, mitreHead, dropHole);

        drawCarvedLayer(mitreHead, bodyFill);

        final Offset pearlPos = Offset(midX, h * 0.12);
        canvas.drawCircle(pearlPos, w * 0.035, bodyFill);
        canvas.drawCircle(pearlPos, w * 0.035, borderStroke);
        break;

      case chess_lib.PieceType.QUEEN:
        final Path rearTiara = Path()
          ..moveTo(midX - w * 0.25, h * 0.22)
          ..quadraticBezierTo(midX, h * 0.25, midX + w * 0.25, h * 0.22)
          ..lineTo(midX, upperRingTopY)
          ..close();
        canvas.drawPath(rearTiara, recessFill);
        canvas.drawPath(rearTiara, borderStroke);

        Path frontTiara = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..lineTo(midX - w * 0.28, h * 0.18)
          ..quadraticBezierTo(midX - w * 0.21, h * 0.23, midX - w * 0.15, h * 0.15)
          ..quadraticBezierTo(midX - w * 0.07, h * 0.21, midX, h * 0.13)
          ..quadraticBezierTo(midX + w * 0.07, h * 0.21, midX + w * 0.15, h * 0.15)
          ..quadraticBezierTo(midX + w * 0.21, h * 0.23, midX + w * 0.28, h * 0.18)
          ..lineTo(midX + ringW, upperRingTopY)
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();

        // Circular negative space hole in center of tiara head
        final Path tiaraHole = Path()
          ..addOval(Rect.fromCircle(center: Offset(midX, h * 0.24), radius: w * 0.055));
        frontTiara = Path.combine(PathOperation.difference, frontTiara, tiaraHole);

        drawCarvedLayer(frontTiara, bodyFill);

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
        Path kBowl = Path()
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

        // Round cutout in center of crown bowl
        final Path crownHole = Path()
          ..addOval(Rect.fromCircle(center: Offset(midX, h * 0.29), radius: w * 0.065));
        kBowl = Path.combine(PathOperation.difference, kBowl, crownHole);

        drawCarvedLayer(kBowl, bodyFill);

        final Path kBand = Path()
          ..moveTo(midX - w * 0.23, h * 0.24)
          ..lineTo(midX - w * 0.24, h * 0.21)
          ..quadraticBezierTo(midX, h * 0.23, midX + w * 0.24, h * 0.21)
          ..lineTo(midX + w * 0.23, h * 0.24)
          ..quadraticBezierTo(midX, h * 0.26, midX - w * 0.23, h * 0.24)
          ..close();
        drawCarvedLayer(kBand, inlayFill);

        final double cx = midX;
        final double cy = h * 0.13;
        final double arm = w * 0.07;
        final double endW = w * 0.055;
        final double coreW = w * 0.015;

        Path cross = Path()
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

        // Small cross-shaped cutout inside cross finial
        final Path crossHole = Path()
          ..moveTo(cx - coreW, cy - endW * 0.6)
          ..lineTo(cx + coreW, cy - endW * 0.6)
          ..lineTo(cx + coreW, cy - coreW)
          ..lineTo(cx + endW * 0.6, cy - coreW)
          ..lineTo(cx + endW * 0.6, cy + coreW)
          ..lineTo(cx + coreW, cy + coreW)
          ..lineTo(cx + coreW, cy + endW * 0.6)
          ..lineTo(cx - coreW, cy + endW * 0.6)
          ..lineTo(cx - coreW, cy + coreW)
          ..lineTo(cx - endW * 0.6, cy + coreW)
          ..lineTo(cx - endW * 0.6, cy - coreW)
          ..lineTo(cx - coreW, cy - coreW)
          ..close();
        cross = Path.combine(PathOperation.difference, cross, crossHole);

        drawCarvedLayer(cross, bodyFill);
        break;

      case chess_lib.PieceType.KNIGHT:
        final Path farEar = Path()
          ..moveTo(midX + w * 0.05, h * 0.25)
          ..lineTo(midX + w * 0.12, h * 0.16)
          ..lineTo(midX + w * 0.16, h * 0.22)
          ..close();
        canvas.drawPath(farEar, recessFill);
        canvas.drawPath(farEar, borderStroke);

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

        Path stallionHead = Path()
          ..moveTo(midX - ringW, upperRingTopY)
          ..cubicTo(
            midX - w * 0.28, h * 0.58,
            midX - w * 0.32, h * 0.42,
            midX - w * 0.30, h * 0.32,
          )
          ..quadraticBezierTo(midX - w * 0.25, h * 0.25, midX - w * 0.15, h * 0.24)
          ..lineTo(midX + w * 0.05, h * 0.20)
          ..lineTo(midX + w * 0.18, h * 0.28)
          ..cubicTo(
            midX + w * 0.18, h * 0.45,
            midX + w * 0.10, h * 0.60,
            midX + ringW, upperRingTopY,
          )
          ..quadraticBezierTo(midX, upperRingTopY + h * 0.03, midX - ringW, upperRingTopY)
          ..close();

        // Eye socket as an actual negative space cutout (hole) so the board shows through
        final Offset eyePos = Offset(midX - w * 0.08, h * 0.28);
        final Path eyeHole = Path()
          ..addOval(Rect.fromCenter(center: eyePos, width: w * 0.065, height: w * 0.045));
        
        // Nostril slit cutout
        final Path nostrilHole = Path()
          ..addOval(Rect.fromCenter(center: Offset(midX - w * 0.24, h * 0.29), width: w * 0.035, height: w * 0.02));

        stallionHead = Path.combine(PathOperation.difference, stallionHead, eyeHole);
        stallionHead = Path.combine(PathOperation.difference, stallionHead, nostrilHole);

        drawCarvedLayer(stallionHead, bodyFill);

        // Cheekbone overlay plate
        final Path cheekbone = Path()
          ..moveTo(midX - w * 0.10, h * 0.32)
          ..quadraticBezierTo(midX + w * 0.05, h * 0.30, midX + w * 0.08, h * 0.42)
          ..quadraticBezierTo(midX, h * 0.52, midX - w * 0.12, h * 0.45)
          ..close();
        drawCarvedLayer(cheekbone, bodyFill);

        final Path nearEar = Path()
          ..moveTo(midX, h * 0.22)
          ..lineTo(midX + w * 0.06, h * 0.12)
          ..lineTo(midX + w * 0.12, h * 0.20)
          ..close();
        drawCarvedLayer(nearEar, bodyFill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DesertPiecePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.isWhite != isWhite ||
      oldDelegate.isHighlighted != isHighlighted;
}
