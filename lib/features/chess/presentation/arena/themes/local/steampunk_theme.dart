import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/themes/chess_theme.dart';
import '../../../shared/themes/animation_group.dart';

class SteampunkTheme extends ChessTheme {
  const SteampunkTheme() : super(id: 'theme5', name: 'Steampunk');

  @override
  Color get lightSquare => const Color(0xFF8D6E63);

  @override
  Color get darkSquare => const Color(0xFF4E342E);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF3E2723);

  @override
  AnimationGroup get animationGroup => AnimationGroup.d;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const Positioned.fill(child: GreaseCheckPulse());
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return GreaseBoardPainter(isLight: isLight);
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: SteampunkPiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
          isHighlighted: isHighlighted,
          rotation: animationValue,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return OilPuddleIndicator(isEnemy: isEnemy);
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const SteampunkSelectionRing();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return MetalShatterEffect(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return const SteamParticleOverlay(); // Steam Particle Ambient: 10 blurry clouds
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: opacity),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Industrial Grease Theme Colors & Painters
// ────────────────────────────────────────────────────────────────────────
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

    final baseColor = isLight
        ? GreaseColors.lightSquare.withValues(alpha: 0.85)
        : GreaseColors.darkSquare;

    final Paint paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

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

    if (random.nextDouble() > 0.5) {
      final cyclePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        size.width * 0.3,
        cyclePaint,
      );
    }

    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(rect.deflate(0.5), edgePaint);
  }

  @override
  bool shouldRepaint(GreaseBoardPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// Steampunk Piece Painter
// ────────────────────────────────────────────────────────────────────────
class SteampunkPiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;
  final bool isHighlighted;
  final double rotation;

  SteampunkPiecePainter({
    required this.type,
    required this.isWhite,
    required this.rotation,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    final Paint bodyFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? const [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFF57F17)]
            : const [Color(0xFF9E9E9E), Color(0xFF424242), Color(0xFF212121)],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    final Paint accentFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isWhite
            ? const [Color(0xFFFFAB91), Color(0xFFD84315), Color(0xFFBF360C)]
            : const [Color(0xFFBCAAA4), Color(0xFF5D4037), Color(0xFF3E2723)],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    final Paint goldFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: const [Color(0xFFFFD54F), Color(0xFFFFF9C4), Color(0xFFFFC107), Color(0xFFFF8F00)],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTRB(midX - w * 0.3, 0, midX + w * 0.3, h));

    final Paint borderStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: isWhite ? 0.85 : 0.95);

    final Paint specularStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = Colors.white.withValues(alpha: isWhite ? 0.7 : 0.25);

    void drawLayer(Path path, Paint fill) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, borderStroke);
    }

    final Path shadowPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(midX + w * 0.04, h * 0.88), width: w * 0.75, height: h * 0.16));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(midX, h * 0.86), width: w * 0.8, height: h * 0.2),
      Paint()
        ..color = (isWhite ? const Color(0xFFFFB300) : const Color(0xFF29B6F6)).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
    );

    final Path basePlate = Path()
      ..moveTo(midX - w * 0.36, h * 0.83)
      ..lineTo(midX - w * 0.36, h * 0.88)
      ..quadraticBezierTo(midX, h * 0.93, midX + w * 0.36, h * 0.88)
      ..lineTo(midX + w * 0.36, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX - w * 0.36, h * 0.83)
      ..close();
    drawLayer(basePlate, bodyFill);

    final Path basePedestal = Path()
      ..moveTo(midX - w * 0.28, h * 0.77)
      ..lineTo(midX - w * 0.34, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX + w * 0.34, h * 0.83)
      ..lineTo(midX + w * 0.28, h * 0.77)
      ..quadraticBezierTo(midX, h * 0.81, midX - w * 0.28, h * 0.77)
      ..close();
    drawLayer(basePedestal, accentFill);

    final Paint rivetPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final Paint rivetHighlight = Paint()..color = Colors.white.withValues(alpha: 0.5);
    void drawRivet(Offset pt) {
      canvas.drawCircle(pt, 2.0, rivetPaint);
      canvas.drawCircle(pt.translate(-0.5, -0.5), 0.8, rivetHighlight);
    }
    drawRivet(Offset(midX - w * 0.22, h * 0.81));
    drawRivet(Offset(midX, h * 0.83));
    drawRivet(Offset(midX + w * 0.22, h * 0.81));

    switch (type) {
      case 'P':
        final Path collar = Path()
          ..moveTo(midX - w * 0.16, h * 0.77)
          ..lineTo(midX - w * 0.12, h * 0.52)
          ..lineTo(midX + w * 0.12, h * 0.52)
          ..lineTo(midX + w * 0.16, h * 0.77)
          ..close();
        drawLayer(collar, bodyFill);

        final Path domeRing = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(midX, h * 0.52), width: w * 0.32, height: h * 0.06),
            const Radius.circular(4.0),
          ));
        drawLayer(domeRing, accentFill);

        final Offset domeCenter = Offset(midX, h * 0.34);
        final double domeRadius = w * 0.16;
        final Path topDome = Path()..addOval(Rect.fromCircle(center: domeCenter, radius: domeRadius));
        drawLayer(topDome, bodyFill);
        
        canvas.drawCircle(
          domeCenter.translate(-domeRadius * 0.3, -domeRadius * 0.3),
          domeRadius * 0.25,
          Paint()..color = Colors.white.withValues(alpha: 0.6),
        );

        drawRivet(Offset(midX - w * 0.18, h * 0.52));
        drawRivet(Offset(midX + w * 0.18, h * 0.52));
        break;

      case 'R':
        final Path towerColumn = Path()
          ..moveTo(midX - w * 0.22, h * 0.77)
          ..lineTo(midX - w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.22, h * 0.77)
          ..close();
        drawLayer(towerColumn, bodyFill);

        final Path band1 = Path()
          ..addRect(Rect.fromCenter(center: Offset(midX, h * 0.68), width: w * 0.46, height: h * 0.05));
        final Path band2 = Path()
          ..addRect(Rect.fromCenter(center: Offset(midX, h * 0.43), width: w * 0.46, height: h * 0.05));
        drawLayer(band1, accentFill);
        drawLayer(band2, accentFill);
        drawRivet(Offset(midX - w * 0.18, h * 0.68));
        drawRivet(Offset(midX + w * 0.18, h * 0.68));
        drawRivet(Offset(midX - w * 0.18, h * 0.43));
        drawRivet(Offset(midX + w * 0.18, h * 0.43));

        final Offset vpCenter = Offset(midX, h * 0.55);
        canvas.drawCircle(vpCenter, w * 0.14, borderStroke);
        final Paint glowCore = Paint()
          ..shader = RadialGradient(
            colors: isWhite
                ? const [Color(0xFFFFF3E0), Color(0xFFFF9800), Color(0xFFE65100)]
                : const [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF006064)],
          ).createShader(Rect.fromCircle(center: vpCenter, radius: w * 0.12));
        canvas.drawCircle(vpCenter, w * 0.12, glowCore);
        canvas.drawLine(
          vpCenter.translate(-w * 0.06, w * 0.06),
          vpCenter.translate(w * 0.06, -w * 0.06),
          Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 1.5,
        );

        final Path topRing = Path()
          ..moveTo(midX - w * 0.28, h * 0.35)
          ..lineTo(midX - w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.28, h * 0.35)
          ..close();
        drawLayer(topRing, accentFill);

        void drawTurret(double tx) {
          final Path turret = Path()
            ..addRect(Rect.fromCenter(center: Offset(tx, h * 0.26), width: w * 0.12, height: h * 0.18));
          drawLayer(turret, bodyFill);
          final Path ventRim = Path()
            ..addRect(Rect.fromCenter(center: Offset(tx, h * 0.17), width: w * 0.14, height: h * 0.03));
          drawLayer(ventRim, accentFill);
        }
        drawTurret(midX - w * 0.18);
        drawTurret(midX);
        drawTurret(midX + w * 0.18);
        break;

      case 'N':
        final Path farEar = Path()
          ..moveTo(midX + w * 0.05, h * 0.26)
          ..lineTo(midX + w * 0.12, h * 0.15)
          ..lineTo(midX + w * 0.18, h * 0.23)
          ..close();
        drawLayer(farEar, accentFill);

        final Path manePlates = Path()
          ..moveTo(midX + w * 0.12, h * 0.25)
          ..lineTo(midX + w * 0.32, h * 0.36)
          ..lineTo(midX + w * 0.22, h * 0.42)
          ..lineTo(midX + w * 0.34, h * 0.52)
          ..lineTo(midX + w * 0.24, h * 0.58)
          ..lineTo(midX + w * 0.30, h * 0.68)
          ..lineTo(midX, h * 0.77)
          ..close();
        drawLayer(manePlates, goldFill);

        final Offset gearHub = Offset(midX, h * 0.50);
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: gearHub, radius: w * 0.18)));
        canvas.drawColor(Colors.black.withValues(alpha: 0.8), BlendMode.srcOver);
        _drawSingleGear(canvas, gearHub, w * 0.15, rotation, Paint()..color = isWhite ? const Color(0xFFFFB300) : const Color(0xFFB0BEC5));
        _drawSingleGear(canvas, gearHub.translate(-w * 0.08, -w * 0.05), w * 0.10, -rotation * 1.5, accentFill);
        canvas.restore();
        canvas.drawCircle(gearHub, w * 0.18, borderStroke);

        final Path stallionHead = Path()
          ..moveTo(midX - w * 0.10, h * 0.77)
          ..cubicTo(midX - w * 0.32, h * 0.62, midX - w * 0.34, h * 0.44, midX - w * 0.30, h * 0.32)
          ..lineTo(midX - w * 0.16, h * 0.23)
          ..lineTo(midX + w * 0.04, h * 0.18)
          ..lineTo(midX + w * 0.18, h * 0.28)
          ..lineTo(midX + w * 0.10, h * 0.50)
          ..lineTo(midX + w * 0.12, h * 0.77)
          ..close();
        drawLayer(stallionHead, bodyFill);

        final Path cheekPlate = Path()
          ..moveTo(midX - w * 0.08, h * 0.32)
          ..lineTo(midX + w * 0.08, h * 0.28)
          ..lineTo(midX + w * 0.12, h * 0.42)
          ..lineTo(midX - w * 0.08, h * 0.48)
          ..close();
        drawLayer(cheekPlate, accentFill);
        drawRivet(Offset(midX - w * 0.04, h * 0.35));
        drawRivet(Offset(midX + w * 0.06, h * 0.40));

        final Path nearEar = Path()
          ..moveTo(midX, h * 0.22)
          ..lineTo(midX + w * 0.06, h * 0.10)
          ..lineTo(midX + w * 0.13, h * 0.20)
          ..close();
        drawLayer(nearEar, bodyFill);

        final Offset eyePos = Offset(midX - w * 0.06, h * 0.26);
        canvas.drawCircle(eyePos, w * 0.03, Paint()..color = Colors.black);
        canvas.drawCircle(
          eyePos,
          w * 0.02,
          Paint()
            ..color = isWhite ? const Color(0xFFFF1744) : const Color(0xFF00E5FF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
        );
        canvas.drawCircle(eyePos.translate(-0.5, -0.5), w * 0.008, Paint()..color = Colors.white);
        break;

      case 'B':
        final Path struts = Path()
          ..moveTo(midX - w * 0.22, h * 0.77)
          ..lineTo(midX - w * 0.15, h * 0.40)
          ..lineTo(midX - w * 0.10, h * 0.40)
          ..lineTo(midX - w * 0.16, h * 0.77)
          ..close()
          ..moveTo(midX + w * 0.22, h * 0.77)
          ..lineTo(midX + w * 0.15, h * 0.40)
          ..lineTo(midX + w * 0.10, h * 0.40)
          ..lineTo(midX + w * 0.16, h * 0.77)
          ..close();
        drawLayer(struts, accentFill);

        final Path centerShaft = Path()
          ..addRect(Rect.fromCenter(center: Offset(midX, h * 0.58), width: w * 0.12, height: h * 0.38));
        drawLayer(centerShaft, bodyFill);

        final Path lowerRing = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(midX, h * 0.40), width: w * 0.38, height: h * 0.05),
            const Radius.circular(4.0),
          ));
        drawLayer(lowerRing, bodyFill);

        final Offset coreHub = Offset(midX, h * 0.25);
        canvas.drawCircle(coreHub, w * 0.14, bodyFill);
        canvas.drawCircle(coreHub, w * 0.14, borderStroke);

        _drawSingleGear(canvas, coreHub, w * 0.18, rotation, goldFill);
        canvas.drawCircle(coreHub, w * 0.05, Paint()..color = Colors.black.withValues(alpha: 0.8));
        canvas.drawCircle(coreHub, w * 0.05, borderStroke);

        final Path finial = Path()
          ..moveTo(midX - w * 0.05, h * 0.12)
          ..lineTo(midX, h * 0.03)
          ..lineTo(midX + w * 0.05, h * 0.12)
          ..close();
        drawLayer(finial, accentFill);
        canvas.drawCircle(Offset(midX, h * 0.03), w * 0.02, goldFill);
        canvas.drawCircle(Offset(midX, h * 0.03), w * 0.02, borderStroke);
        break;

      case 'Q':
        final Path robe = Path()
          ..moveTo(midX - w * 0.26, h * 0.77)
          ..cubicTo(midX - w * 0.22, h * 0.55, midX - w * 0.28, h * 0.45, midX - w * 0.12, h * 0.38)
          ..lineTo(midX + w * 0.12, h * 0.38)
          ..cubicTo(midX + w * 0.28, h * 0.45, midX + w * 0.22, h * 0.55, midX + w * 0.26, h * 0.77)
          ..close();
        drawLayer(robe, bodyFill);

        for (int i = 0; i < 4; i++) {
          final double ry = h * 0.45 + i * h * 0.07;
          final double rw = w * 0.22 - i * w * 0.02;
          final Path rib = Path()
            ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(midX, ry), width: rw, height: h * 0.035),
              const Radius.circular(2.0),
            ));
          drawLayer(rib, accentFill);
        }

        final Path archway = Path()
          ..moveTo(midX - w * 0.18, h * 0.32)
          ..cubicTo(midX - w * 0.18, h * 0.15, midX + w * 0.18, h * 0.15, midX + w * 0.18, h * 0.32)
          ..close();
        canvas.save();
        canvas.clipPath(archway);
        canvas.drawColor(Colors.black.withValues(alpha: 0.85), BlendMode.srcOver);
        final Offset topGearPt = Offset(midX, h * 0.22);
        final Offset bottomGearPt = Offset(midX, h * 0.29);
        _drawSingleGear(canvas, topGearPt, w * 0.09, rotation * 1.2, goldFill);
        _drawSingleGear(canvas, bottomGearPt, w * 0.07, -rotation * 1.5, accentFill);
        canvas.restore();
        canvas.drawPath(archway, borderStroke);

        final Path tiara = Path()
          ..moveTo(midX - w * 0.20, h * 0.35)
          ..lineTo(midX - w * 0.34, h * 0.16)
          ..lineTo(midX - w * 0.18, h * 0.22)
          ..lineTo(midX - w * 0.14, h * 0.11)
          ..lineTo(midX, h * 0.18)
          ..lineTo(midX + w * 0.14, h * 0.11)
          ..lineTo(midX + w * 0.18, h * 0.22)
          ..lineTo(midX + w * 0.34, h * 0.16)
          ..lineTo(midX + w * 0.20, h * 0.35)
          ..close();
        drawLayer(tiara, bodyFill);

        final List<Offset> qPeaks = [
          Offset(midX - w * 0.34, h * 0.16),
          Offset(midX - w * 0.14, h * 0.11),
          Offset(midX + w * 0.14, h * 0.11),
          Offset(midX + w * 0.34, h * 0.16),
        ];
        for (final pt in qPeaks) {
          canvas.drawCircle(pt, w * 0.03, accentFill);
          canvas.drawCircle(pt, w * 0.03, borderStroke);
          canvas.drawCircle(pt.translate(-0.5, -0.5), w * 0.01, Paint()..color = Colors.white);
        }
        break;

      case 'K':
      default:
        final Path kingPillar = Path()
          ..moveTo(midX - w * 0.22, h * 0.77)
          ..lineTo(midX - w * 0.22, h * 0.35)
          ..lineTo(midX + w * 0.22, h * 0.35)
          ..lineTo(midX + w * 0.22, h * 0.77)
          ..close();
        drawLayer(kingPillar, bodyFill);

        final Path sideShieldLeft = Path()
          ..moveTo(midX - w * 0.26, h * 0.65)
          ..lineTo(midX - w * 0.26, h * 0.45)
          ..lineTo(midX - w * 0.20, h * 0.42)
          ..lineTo(midX - w * 0.20, h * 0.68)
          ..close();
        final Path sideShieldRight = Path()
          ..moveTo(midX + w * 0.26, h * 0.65)
          ..lineTo(midX + w * 0.26, h * 0.45)
          ..lineTo(midX + w * 0.20, h * 0.42)
          ..lineTo(midX + w * 0.20, h * 0.68)
          ..close();
        drawLayer(sideShieldLeft, accentFill);
        drawLayer(sideShieldRight, accentFill);
        drawRivet(Offset(midX - w * 0.23, h * 0.46));
        drawRivet(Offset(midX - w * 0.23, h * 0.62));
        drawRivet(Offset(midX + w * 0.23, h * 0.46));
        drawRivet(Offset(midX + w * 0.23, h * 0.62));

        final Offset kHub = Offset(midX, h * 0.54);
        _drawSingleGear(canvas, kHub, w * 0.22, rotation, goldFill);
        canvas.drawCircle(kHub, w * 0.06, Paint()..color = const Color(0xFF212121));
        canvas.drawCircle(kHub, w * 0.06, borderStroke);
        drawRivet(kHub);

        final Path kCrownBase = Path()
          ..moveTo(midX - w * 0.28, h * 0.35)
          ..lineTo(midX - w * 0.32, h * 0.24)
          ..lineTo(midX + w * 0.32, h * 0.24)
          ..lineTo(midX + w * 0.28, h * 0.35)
          ..close();
        drawLayer(kCrownBase, bodyFill);
        
        final Path kBelt = Path()
          ..addRect(Rect.fromCenter(center: Offset(midX, h * 0.29), width: w * 0.54, height: h * 0.035));
        drawLayer(kBelt, accentFill);

        final double cx = midX;
        final double cy = h * 0.14;
        final double arm = w * 0.08;
        final double thick = w * 0.035;

        final Path valveCross = Path()
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: thick, height: arm * 2))
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: arm * 2, height: thick));
        drawLayer(valveCross, goldFill);

        canvas.drawCircle(Offset(cx, cy), thick * 0.6, accentFill);
        canvas.drawCircle(Offset(cx, cy), thick * 0.6, borderStroke);
        canvas.drawCircle(Offset(cx, cy), thick * 0.2, Paint()..color = Colors.black);
        break;
    }

    final Path sheen = Path()
      ..moveTo(midX - w * 0.32, h * 0.85)
      ..lineTo(midX - w * 0.25, h * 0.78);
    canvas.drawPath(sheen, specularStroke);
  }

  void _drawSingleGear(Canvas canvas, Offset center, double radius, double rotValue, Paint fillPaint) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotValue * 2 * math.pi);

    final Path gearPath = Path();
    const int teeth = 10;
    final double innerR = radius * 0.82;

    for (int i = 0; i < teeth * 2; i++) {
      final double r = (i % 2 == 0) ? radius : innerR;
      final double angle = (i / (teeth * 2)) * 2 * math.pi;
      final double nextAngle = ((i + 1) / (teeth * 2)) * 2 * math.pi;
      final double midAngle = (angle + nextAngle) / 2;

      final Offset pt = Offset(math.cos(angle) * r, math.sin(angle) * r);
      final Offset ptMid = Offset(math.cos(midAngle) * r, math.sin(midAngle) * r);

      if (i == 0) {
        gearPath.moveTo(pt.dx, pt.dy);
      } else {
        gearPath.quadraticBezierTo(ptMid.dx, ptMid.dy, pt.dx, pt.dy);
      }
    }
    gearPath.close();

    canvas.drawPath(gearPath, fillPaint);
    canvas.drawPath(
      gearPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.black.withValues(alpha: 0.6),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SteampunkPiecePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.isWhite != isWhite ||
      oldDelegate.isHighlighted != isHighlighted ||
      oldDelegate.rotation != rotation;
}

// ────────────────────────────────────────────────────────────────────────
// Steam Particle Ambient Overlay (Steam clouds)
// ────────────────────────────────────────────────────────────────────────
class SteamParticleOverlay extends StatefulWidget {
  const SteamParticleOverlay({super.key});

  @override
  State<SteamParticleOverlay> createState() => _SteamParticleOverlayState();
}

class _SteamParticleOverlayState extends State<SteamParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SteamCloud> _clouds = List.generate(
    10, // Reduced from 12 as per spec
    (_) => _SteamCloud(),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SteamPainter(_clouds, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SteamCloud {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double size = math.Random().nextDouble() * 30 + 20;
  double speed = math.Random().nextDouble() * 0.1 + 0.05;
  double drift = math.Random().nextDouble() * 0.2 - 0.1;
  double opacity = math.Random().nextDouble() * 0.2; // Max opacity 0.2 as per spec
}

class _SteamPainter extends CustomPainter {
  final List<_SteamCloud> clouds;
  final double animationValue;

  _SteamPainter(this.clouds, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var c in clouds) {
      final dx = size.width * ((c.x + animationValue * c.drift) % 1.0);
      final dy = size.height * ((c.y - animationValue * c.speed) % 1.0);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: c.opacity * (1.0 - (dy / size.height)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

      canvas.drawCircle(Offset(dx, dy), c.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

// ────────────────────────────────────────────────────────────────────────
// Metal Shatter Capture Effect
// ────────────────────────────────────────────────────────────────────────
class MetalShatterEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const MetalShatterEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<MetalShatterEffect> createState() => _MetalShatterEffectState();
}

class _MetalShatterEffectState extends State<MetalShatterEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<_MetalShard> _shards;

  @override
  void initState() {
    super.initState();
    _shards = List.generate(10, (_) => _MetalShard()); // Reduced to 10 as per spec
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reduced to 800ms
    );
    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _MetalShatterPainter(
            _shards,
            _controller.value,
            widget.position,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _MetalShard {
  double angle = math.Random().nextDouble() * 2 * math.pi;
  double dist = math.Random().nextDouble() * 120 + 40;
  double size = math.Random().nextDouble() * 8 + 4;
  bool isGold = math.Random().nextBool();
}

class _MetalShatterPainter extends CustomPainter {
  final List<_MetalShard> shards;
  final double progress;
  final Offset center;

  _MetalShatterPainter(this.shards, this.progress, this.center);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    for (var shard in shards) {
      final paint = Paint()
        ..color = (shard.isGold ? const Color(0xFFDAA520) : const Color(0xFF424242))
            .withValues(alpha: 1.0 - progress)
        ..style = PaintingStyle.fill;

      final t = Curves.easeOutCubic.transform(progress);
      final dx = center.dx + math.cos(shard.angle) * shard.dist * t;
      final dy = center.dy + math.sin(shard.angle) * shard.dist * t;

      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(dx, dy),
          width: shard.size,
          height: shard.size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MetalShatterPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ────────────────────────────────────────────────────────────────────────
// Steampunk Selection Ring (Spinning Gear Overlay)
// ────────────────────────────────────────────────────────────────────────
class SteampunkSelectionRing extends StatefulWidget {
  const SteampunkSelectionRing({super.key});

  @override
  State<SteampunkSelectionRing> createState() => _SteampunkSelectionRingState();
}

class _SteampunkSelectionRingState extends State<SteampunkSelectionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return IgnorePointer(
          child: Center(
            child: Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(60, 60),
                painter: _GearSelectionPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GearSelectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.46;

    final Paint ringPaint = Paint()
      ..color = GreaseColors.hazardYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, ringPaint);

    final Paint stripePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < 12; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * math.pi / 6),
        math.pi / 12,
        false,
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GearSelectionPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// Oil Puddle Indicator (Move Hint)
// ────────────────────────────────────────────────────────────────────────
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
            ),
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

// ────────────────────────────────────────────────────────────────────────
// Grease Check Pulse
// ────────────────────────────────────────────────────────────────────────
class GreaseCheckPulse extends StatefulWidget {
  const GreaseCheckPulse({super.key});

  @override
  State<GreaseCheckPulse> createState() => _GreaseCheckPulseState();
}

class _GreaseCheckPulseState extends State<GreaseCheckPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3 * _controller.value),
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2 * _controller.value),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}
