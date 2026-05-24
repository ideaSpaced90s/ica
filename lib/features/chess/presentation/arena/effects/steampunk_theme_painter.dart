import 'dart:math' as math;
import 'package:flutter/material.dart';

/// State-of-the-art high-fidelity programmatic vector painter for Steampunk Theme pieces.
/// Inspired directly by premium sprite sheets, featuring multi-layered materials (brass,
/// copper, oxidized steel, bronze), dynamic rotating gears, glowing viewports, and heavy depth.
class SteampunkPiecePainter extends CustomPainter {
  final String type; // K, Q, B, N, R, P
  final bool isWhite;
  final bool isHighlighted;
  final double rotation; // Animation value mapped to gear turning

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

    // --- 1. Premium Metallic Gradients & Materials ---
    // Primary Body Material
    final Paint bodyFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWhite
            ? const [
                Color(0xFFFFE082), // Pale Polished Gold
                Color(0xFFFFB300), // Rich Brass
                Color(0xFFF57F17), // Deep Amber Brass
              ]
            : const [
                Color(0xFF9E9E9E), // Machined Steel
                Color(0xFF424242), // Gunmetal
                Color(0xFF212121), // Deep Iron
              ],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    // Secondary Accent Material (Pipes, Struts, Plates)
    final Paint accentFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isWhite
            ? const [
                Color(0xFFFFAB91), // Burnished Copper
                Color(0xFFD84315), // Deep Oxidized Copper
                Color(0xFFBF360C), // Dark Rust Copper
              ]
            : const [
                Color(0xFFBCAAA4), // Aged Bronze
                Color(0xFF5D4037), // Dark Patina Bronze
                Color(0xFF3E2723), // Deep Oil Rust
              ],
      ).createShader(Rect.fromLTRB(0, 0, w, h));

    // Polished Pure Gold highlights for central gears/crowns
    final Paint goldFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          Color(0xFFFFD54F),
          Color(0xFFFFF9C4),
          Color(0xFFFFC107),
          Color(0xFFFF8F00),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTRB(midX - w * 0.3, 0, midX + w * 0.3, h));

    // Sharp external line-art border for pristine legibility across squares
    final Paint borderStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = isWhite
          ? Colors.black.withValues(alpha: 0.85)
          : Colors.black.withValues(alpha: 0.95);

    // Subtle inline highlight mapping specular sheen
    final Paint specularStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = isWhite
          ? Colors.white.withValues(alpha: 0.7)
          : Colors.white.withValues(alpha: 0.25);

    // Helper to paint filled shapes with high contrast outlines
    void drawLayer(Path path, Paint fill) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, borderStroke);
    }

    // --- 2. Depth Perspective Base Drop Shadow ---
    final Path shadowPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(midX + w * 0.04, h * 0.88),
        width: w * 0.75,
        height: h * 0.16,
      ));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    // Subtle atmospheric floor backlighting
    canvas.drawOval(
      Rect.fromCenter(center: Offset(midX, h * 0.86), width: w * 0.8, height: h * 0.2),
      Paint()
        ..color = (isWhite ? const Color(0xFFFFB300) : const Color(0xFF29B6F6))
            .withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0),
    );

    // --- 3. Universal Mechanical Foundation Base ---
    // Bottom flange base plate
    final Path basePlate = Path()
      ..moveTo(midX - w * 0.36, h * 0.83)
      ..lineTo(midX - w * 0.36, h * 0.88)
      ..quadraticBezierTo(midX, h * 0.93, midX + w * 0.36, h * 0.88)
      ..lineTo(midX + w * 0.36, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX - w * 0.36, h * 0.83)
      ..close();
    drawLayer(basePlate, bodyFill);

    // Base core pedestal housing
    final Path basePedestal = Path()
      ..moveTo(midX - w * 0.28, h * 0.77)
      ..lineTo(midX - w * 0.34, h * 0.83)
      ..quadraticBezierTo(midX, h * 0.88, midX + w * 0.34, h * 0.83)
      ..lineTo(midX + w * 0.28, h * 0.77)
      ..quadraticBezierTo(midX, h * 0.81, midX - w * 0.28, h * 0.77)
      ..close();
    drawLayer(basePedestal, accentFill);

    // Embedded rivet bolts on the base pedestal
    final Paint rivetPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final Paint rivetHighlight = Paint()..color = Colors.white.withValues(alpha: 0.5);
    void drawRivet(Offset pt) {
      canvas.drawCircle(pt, 2.0, rivetPaint);
      canvas.drawCircle(pt.translate(-0.5, -0.5), 0.8, rivetHighlight);
    }
    drawRivet(Offset(midX - w * 0.22, h * 0.81));
    drawRivet(Offset(midX, h * 0.83));
    drawRivet(Offset(midX + w * 0.22, h * 0.81));

    // --- 4. Piece-Specific Steampunk Vector Geometries ---
    switch (type) {
      case 'P': // Pawn: Pressure valve cylinder with polished dome
        // Steam Pipe Collar
        final Path collar = Path()
          ..moveTo(midX - w * 0.16, h * 0.77)
          ..lineTo(midX - w * 0.12, h * 0.52)
          ..lineTo(midX + w * 0.12, h * 0.52)
          ..lineTo(midX + w * 0.16, h * 0.77)
          ..close();
        drawLayer(collar, bodyFill);

        // Center steam-pressure dome ring
        final Path domeRing = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(midX, h * 0.52), width: w * 0.32, height: h * 0.06),
            const Radius.circular(4.0),
          ));
        drawLayer(domeRing, accentFill);

        // Top Copper Sphere Unit
        final Offset domeCenter = Offset(midX, h * 0.34);
        final double domeRadius = w * 0.16;
        final Path topDome = Path()..addOval(Rect.fromCircle(center: domeCenter, radius: domeRadius));
        drawLayer(topDome, bodyFill);
        
        // Specular dome dot
        canvas.drawCircle(
          domeCenter.translate(-domeRadius * 0.3, -domeRadius * 0.3),
          domeRadius * 0.25,
          Paint()..color = Colors.white.withValues(alpha: 0.6),
        );

        // Side valve switch bolts
        drawRivet(Offset(midX - w * 0.18, h * 0.52));
        drawRivet(Offset(midX + w * 0.18, h * 0.52));
        break;

      case 'R': // Rook: Heavy boiler furnace tower with internal glowing steam core
        // Main tower body
        final Path towerColumn = Path()
          ..moveTo(midX - w * 0.22, h * 0.77)
          ..lineTo(midX - w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.22, h * 0.77)
          ..close();
        drawLayer(towerColumn, bodyFill);

        // Heavy lateral iron structural reinforcing bands
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

        // Central Viewport Core Frame
        final Offset vpCenter = Offset(midX, h * 0.55);
        canvas.drawCircle(vpCenter, w * 0.14, borderStroke);
        // Glowing internal energy furnace/steam blast
        final Paint glowCore = Paint()
          ..shader = RadialGradient(
            colors: isWhite
                ? const [Color(0xFFFFF3E0), Color(0xFFFF9800), Color(0xFFE65100)]
                : const [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF006064)],
          ).createShader(Rect.fromCircle(center: vpCenter, radius: w * 0.12));
        canvas.drawCircle(vpCenter, w * 0.12, glowCore);
        // Viewport glass line reflection
        canvas.drawLine(
          vpCenter.translate(-w * 0.06, w * 0.06),
          vpCenter.translate(w * 0.06, -w * 0.06),
          Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 1.5,
        );

        // Flared Battlement Base Ring
        final Path topRing = Path()
          ..moveTo(midX - w * 0.28, h * 0.35)
          ..lineTo(midX - w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.22, h * 0.40)
          ..lineTo(midX + w * 0.28, h * 0.35)
          ..close();
        drawLayer(topRing, accentFill);

        // Distinct Industrial Triple Smokestack Turrets
        void drawTurret(double tx) {
          final Path turret = Path()
            ..addRect(Rect.fromCenter(center: Offset(tx, h * 0.26), width: w * 0.12, height: h * 0.18));
          drawLayer(turret, bodyFill);
          // Smokestack vent rim
          final Path ventRim = Path()
            ..addRect(Rect.fromCenter(center: Offset(tx, h * 0.17), width: w * 0.14, height: h * 0.03));
          drawLayer(ventRim, accentFill);
        }
        drawTurret(midX - w * 0.18);
        drawTurret(midX);
        drawTurret(midX + w * 0.18);
        break;

      case 'N': // Knight: Clockwork mechanical stallion with moving gears and glowing eye
        // Back-layer ear plating
        final Path farEar = Path()
          ..moveTo(midX + w * 0.05, h * 0.26)
          ..lineTo(midX + w * 0.12, h * 0.15)
          ..lineTo(midX + w * 0.18, h * 0.23)
          ..close();
        drawLayer(farEar, accentFill);

        // Layered brass neck plating / segmented mechanical mane
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

        // Internal exposed core cutout rendering automated rotating gears
        final Offset gearHub = Offset(midX, h * 0.50);
        canvas.save();
        canvas.clipPath(Path()..addOval(Rect.fromCircle(center: gearHub, radius: w * 0.18)));
        canvas.drawColor(Colors.black.withValues(alpha: 0.8), BlendMode.srcOver);
        // Draw spinning internal gear
        _drawSingleGear(canvas, gearHub, w * 0.15, rotation, Paint()..color = isWhite ? const Color(0xFFFFB300) : const Color(0xFFB0BEC5));
        _drawSingleGear(canvas, gearHub.translate(-w * 0.08, -w * 0.05), w * 0.10, -rotation * 1.5, accentFill);
        canvas.restore();
        // Inner cutout rim overlay
        canvas.drawCircle(gearHub, w * 0.18, borderStroke);

        // Main Mechanical Head & Snout block
        final Path stallionHead = Path()
          ..moveTo(midX - w * 0.10, h * 0.77) // Lower chest
          ..cubicTo(
            midX - w * 0.32, h * 0.62,
            midX - w * 0.34, h * 0.44,
            midX - w * 0.30, h * 0.32,
          ) // Powerful mechanical chest profile
          ..lineTo(midX - w * 0.16, h * 0.23) // Snout bridge up
          ..lineTo(midX + w * 0.04, h * 0.18) // Forehead crest
          ..lineTo(midX + w * 0.18, h * 0.28) // Crown
          ..lineTo(midX + w * 0.10, h * 0.50) // Mid neck inner
          ..lineTo(midX + w * 0.12, h * 0.77)
          ..close();
        drawLayer(stallionHead, bodyFill);

        // Raised contoured Cheek armor plate
        final Path cheekPlate = Path()
          ..moveTo(midX - w * 0.08, h * 0.32)
          ..lineTo(midX + w * 0.08, h * 0.28)
          ..lineTo(midX + w * 0.12, h * 0.42)
          ..lineTo(midX - w * 0.08, h * 0.48)
          ..close();
        drawLayer(cheekPlate, accentFill);
        drawRivet(Offset(midX - w * 0.04, h * 0.35));
        drawRivet(Offset(midX + w * 0.06, h * 0.40));

        // Near ear component
        final Path nearEar = Path()
          ..moveTo(midX, h * 0.22)
          ..lineTo(midX + w * 0.06, h * 0.10)
          ..lineTo(midX + w * 0.13, h * 0.20)
          ..close();
        drawLayer(nearEar, bodyFill);

        // Radiant Optical Sensor Eye
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

      case 'B': // Bishop: Precision gyroscopic mitre topped with a Tesla finial
        // Angular copper lateral support struts
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

        // Inner vertical mechanical shaft
        final Path centerShaft = Path()
          ..addRect(Rect.fromCenter(center: Offset(midX, h * 0.58), width: w * 0.12, height: h * 0.38));
        drawLayer(centerShaft, bodyFill);

        // Lower Gyro Frame Ring
        final Path lowerRing = Path()
          ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(midX, h * 0.40), width: w * 0.38, height: h * 0.05),
            const Radius.circular(4.0),
          ));
        drawLayer(lowerRing, bodyFill);

        // Suspended central energy core sphere
        final Offset coreHub = Offset(midX, h * 0.25);
        canvas.drawCircle(coreHub, w * 0.14, bodyFill);
        canvas.drawCircle(coreHub, w * 0.14, borderStroke);

        // Orbiting custom cog-ring overlay centered on the core hub
        _drawSingleGear(canvas, coreHub, w * 0.18, rotation, goldFill);
        // Core hub center hole
        canvas.drawCircle(coreHub, w * 0.05, Paint()..color = Colors.black.withValues(alpha: 0.8));
        canvas.drawCircle(coreHub, w * 0.05, borderStroke);

        // Top Tesla-coil / Gyro finial point
        final Path finial = Path()
          ..moveTo(midX - w * 0.05, h * 0.12)
          ..lineTo(midX, h * 0.03)
          ..lineTo(midX + w * 0.05, h * 0.12)
          ..close();
        drawLayer(finial, accentFill);
        canvas.drawCircle(Offset(midX, h * 0.03), w * 0.02, goldFill);
        canvas.drawCircle(Offset(midX, h * 0.03), w * 0.02, borderStroke);
        break;

      case 'Q': // Queen: Flared skirts, layered corset piping, counter-rotating open core crown
        // Outer flared side mechanical robes
        final Path robe = Path()
          ..moveTo(midX - w * 0.26, h * 0.77)
          ..cubicTo(
            midX - w * 0.22, h * 0.55,
            midX - w * 0.28, h * 0.45,
            midX - w * 0.12, h * 0.38,
          )
          ..lineTo(midX + w * 0.12, h * 0.38)
          ..cubicTo(
            midX + w * 0.28, h * 0.45,
            midX + w * 0.22, h * 0.55,
            midX + w * 0.26, h * 0.77,
          )
          ..close();
        drawLayer(robe, bodyFill);

        // Embedded central corset horizontal steam-vent ribbing
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

        // Inner arched opening showcasing dynamic nested heart clockwork mechanisms
        final Path archway = Path()
          ..moveTo(midX - w * 0.18, h * 0.32)
          ..cubicTo(
            midX - w * 0.18, h * 0.15,
            midX + w * 0.18, h * 0.15,
            midX + w * 0.18, h * 0.32,
          )
          ..close();
        canvas.save();
        canvas.clipPath(archway);
        canvas.drawColor(Colors.black.withValues(alpha: 0.85), BlendMode.srcOver);
        // Dual interlocked counter-spinning nested gears
        final Offset topGearPt = Offset(midX, h * 0.22);
        final Offset bottomGearPt = Offset(midX, h * 0.29);
        _drawSingleGear(canvas, topGearPt, w * 0.09, rotation * 1.2, goldFill);
        _drawSingleGear(canvas, bottomGearPt, w * 0.07, -rotation * 1.5, accentFill);
        canvas.restore();
        canvas.drawPath(archway, borderStroke);

        // Flaring multi-toothed wide Tiara Crown
        final Path tiara = Path()
          ..moveTo(midX - w * 0.20, h * 0.35)
          ..lineTo(midX - w * 0.34, h * 0.16) // Peak 1 far left
          ..lineTo(midX - w * 0.18, h * 0.22) // Dip 1
          ..lineTo(midX - w * 0.14, h * 0.11) // Peak 2
          ..lineTo(midX, h * 0.18)            // Center dip
          ..lineTo(midX + w * 0.14, h * 0.11) // Peak 3
          ..lineTo(midX + w * 0.18, h * 0.22) // Dip 2
          ..lineTo(midX + w * 0.34, h * 0.16) // Peak 4 far right
          ..lineTo(midX + w * 0.20, h * 0.35)
          ..close();
        drawLayer(tiara, bodyFill);

        // Crowning polished copper finial studs on all 4 crown peaks
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

      case 'K': // King: Command housing pillar, continuous outer driving gear, pressure valve top
      default:
        // Main core pillar column
        final Path kingPillar = Path()
          ..moveTo(midX - w * 0.22, h * 0.77)
          ..lineTo(midX - w * 0.22, h * 0.35)
          ..lineTo(midX + w * 0.22, h * 0.35)
          ..lineTo(midX + w * 0.22, h * 0.77)
          ..close();
        drawLayer(kingPillar, bodyFill);

        // Lateral bolt-on protective shield plates
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

        // Center commanding driving Gear spinning prominently on the front block
        final Offset kHub = Offset(midX, h * 0.54);
        _drawSingleGear(canvas, kHub, w * 0.22, rotation, goldFill);
        canvas.drawCircle(kHub, w * 0.06, Paint()..color = const Color(0xFF212121));
        canvas.drawCircle(kHub, w * 0.06, borderStroke);
        drawRivet(kHub);

        // Flared Command Crown Ring Base
        final Path kCrownBase = Path()
          ..moveTo(midX - w * 0.28, h * 0.35)
          ..lineTo(midX - w * 0.32, h * 0.24)
          ..lineTo(midX + w * 0.32, h * 0.24)
          ..lineTo(midX + w * 0.28, h * 0.35)
          ..close();
        drawLayer(kCrownBase, bodyFill);
        
        // Embossed internal decorative cross belt
        final Path kBelt = Path()
          ..addRect(Rect.fromCenter(center: Offset(midX, h * 0.29), width: w * 0.54, height: h * 0.035));
        drawLayer(kBelt, accentFill);

        // Prominent mechanical Top Exhaust Pressure Cross / Relief Valve finial
        final double cx = midX;
        final double cy = h * 0.14;
        final double arm = w * 0.08;
        final double thick = w * 0.035;

        final Path valveCross = Path()
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: thick, height: arm * 2))
          ..addRect(Rect.fromCenter(center: Offset(cx, cy), width: arm * 2, height: thick));
        drawLayer(valveCross, goldFill);

        // Central cross pressure release cap ring
        canvas.drawCircle(Offset(cx, cy), thick * 0.6, accentFill);
        canvas.drawCircle(Offset(cx, cy), thick * 0.6, borderStroke);
        canvas.drawCircle(Offset(cx, cy), thick * 0.2, Paint()..color = Colors.black);
        break;
    }

    // --- 5. Universal Crisp Specular Overlays ---
    // Smooth left-edge light gleam contour
    final Path sheen = Path()
      ..moveTo(midX - w * 0.32, h * 0.85)
      ..lineTo(midX - w * 0.25, h * 0.78);
    canvas.drawPath(sheen, specularStroke);
  }

  /// Reusable helper generating accurate mechanical cogwheels/gears at any angle and scale.
  void _drawSingleGear(
    Canvas canvas,
    Offset center,
    double radius,
    double rotValue,
    Paint fillPaint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotValue * 2 * math.pi);

    final Path gearPath = Path();
    const int teeth = 10; // Highly aesthetic visual cog count
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
        // Smooth gear tooth profile mapping standard watchmaking design
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
