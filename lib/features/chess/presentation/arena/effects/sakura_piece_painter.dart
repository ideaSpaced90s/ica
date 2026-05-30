import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

/// Sakura Theme Piece Painter — Shogi-Style Japanese Aesthetic
///
/// Each piece uses a flat pentagonal tile body (inspired by shogi ken / pieces)
/// with a hand-carved mon (家紋 family crest) or kamon icon unique to each role.
///
/// Color Palette (high-contrast against Sakura board):
///   White pieces : Warm Ivory body  (#FFFDF0) + Vermillion (#C0392B) accents
///   Black pieces : Deep Urushi Black (#1A1410) body + Gold (#D4A017) accents
///
/// Board reference:
///   Light squares : #FCE4EC  (pastel cherry pink)
///   Dark squares  : #2E3D30  (deep moss green)
class SakuraPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;

  const SakuraPiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  // ─── Color Palette ───────────────────────────────────────────────────────
  static const _ivoryTop    = Color(0xFFFFF8E7);
  static const _ivoryMid    = Color(0xFFF5E6C0);
  static const _ivoryBot    = Color(0xFFE2C98A);
  static const _vermillion  = Color(0xFFC0392B); // accent / icon for white
  static const _lacquerLine = Color(0xFF8B1A12); // darker vermillion outline

  static const _urushiTop   = Color(0xFF1E1A16);
  static const _urushiMid   = Color(0xFF120E0B);
  static const _urushiBot   = Color(0xFF0A0806);
  static const _goldAcc     = Color(0xFFD4A017); // accent / icon for black
  static const _goldDark    = Color(0xFF9E7510); // darker gold

  static const _shadowColor = Color(0x55000000);
  static const _highlightGlow = Color(0xAAFFD54F);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Drop shadow ──────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + w * 0.02, h * 0.92), width: w * 0.76, height: h * 0.10),
      Paint()
        ..color = _shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // ── Selection glow ───────────────────────────────────────────────────
    if (isHighlighted) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, h * 0.88), width: w * 0.90, height: h * 0.22),
        Paint()
          ..color = _highlightGlow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // ── Shogi-style pentagonal tile body ─────────────────────────────────
    //   Wide at bottom, tapers to a pointed/rounded top — classic ken shape.
    final tileTop    = h * 0.08;
    final tilePeak   = h * 0.04;
    final tileMidY   = h * 0.38;
    final tileBot    = h * 0.86;
    final tileHalfW  = w * 0.40;
    final tileMidHW  = w * 0.44;

    final bodyPath = Path()
      ..moveTo(cx, tilePeak)                              // tip of pentagon
      ..quadraticBezierTo(cx + w * 0.28, tileTop, cx + tileMidHW, tileMidY)
      ..quadraticBezierTo(cx + tileHalfW + w * 0.02, h * 0.62, cx + tileHalfW, tileBot)
      ..quadraticBezierTo(cx, tileBot + h * 0.03, cx - tileHalfW, tileBot)
      ..quadraticBezierTo(cx - tileMidHW - w * 0.02, h * 0.62, cx - tileMidHW, tileMidY)
      ..quadraticBezierTo(cx - w * 0.28, tileTop, cx, tilePeak)
      ..close();

    // Body fill — gradient wood / lacquer
    final bodyGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isWhite
          ? const [_ivoryTop, _ivoryMid, _ivoryBot]
          : const [_urushiTop, _urushiMid, _urushiBot],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(bodyPath, Paint()..shader = bodyGrad..style = PaintingStyle.fill);

    // Specular sheen on left edge
    final sheenPath = Path()
      ..moveTo(cx, tilePeak)
      ..quadraticBezierTo(cx - w * 0.14, tileTop + h * 0.05, cx - tileMidHW + w * 0.04, tileMidY)
      ..quadraticBezierTo(cx - tileMidHW, h * 0.55, cx - tileHalfW + w * 0.02, tileBot - h * 0.05)
      ..quadraticBezierTo(cx - w * 0.10, tileBot, cx, tilePeak);
    canvas.drawPath(
      sheenPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = (isWhite ? Colors.white : Colors.white).withValues(alpha: isWhite ? 0.18 : 0.06),
    );

    // Outer border stroke
    final borderColor = isWhite ? const Color(0xFF3E2010) : const Color(0xFF000000);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.030
        ..color = borderColor
        ..strokeJoin = StrokeJoin.round,
    );

    // Inner bevel line (parallel, inset)
    final bevelPath = Path()
      ..moveTo(cx, tilePeak + h * 0.05)
      ..quadraticBezierTo(cx + w * 0.22, tileTop + h * 0.07, cx + tileMidHW - w * 0.06, tileMidY + h * 0.05)
      ..quadraticBezierTo(cx + tileHalfW - w * 0.05, h * 0.64, cx + tileHalfW - w * 0.05, tileBot - h * 0.06)
      ..quadraticBezierTo(cx, tileBot - h * 0.02, cx - tileHalfW + w * 0.05, tileBot - h * 0.06)
      ..quadraticBezierTo(cx - tileMidHW + w * 0.06, h * 0.64, cx - tileMidHW + w * 0.06, tileMidY + h * 0.05)
      ..quadraticBezierTo(cx - w * 0.22, tileTop + h * 0.07, cx, tilePeak + h * 0.05)
      ..close();

    final accentColor = isWhite ? _vermillion : _goldAcc;
    canvas.drawPath(
      bevelPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012
        ..color = accentColor.withValues(alpha: 0.70)
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Mon / Crest icon centered on tile ────────────────────────────────
    final iconCenterY = h * 0.50;
    _drawPieceIcon(canvas, size, Offset(cx, iconCenterY), accentColor);
  }

  // ─── Icon Dispatcher ─────────────────────────────────────────────────────
  void _drawPieceIcon(Canvas canvas, Size size, Offset center, Color accent) {
    final w = size.width;
    final iconR = w * 0.24; // icon bounding radius

    final iconFill = Paint()
      ..style = PaintingStyle.fill
      ..color = accent;
    final iconFillDim = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.55);
    final iconStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = isWhite ? _lacquerLine : _goldDark;

    switch (type) {
      case chess_lib.PieceType.KING:
        _drawLotusKing(canvas, center, iconR, iconFill, iconStroke, accent, isWhite);
        break;
      case chess_lib.PieceType.QUEEN:
        _drawPlumBlossomQueen(canvas, center, iconR, iconFill, iconStroke);
        break;
      case chess_lib.PieceType.ROOK:
        _drawToriiRook(canvas, size, center, iconR, iconFill, iconFillDim, iconStroke);
        break;
      case chess_lib.PieceType.BISHOP:
        _drawDiamondBishop(canvas, center, iconR, iconFill, iconStroke);
        break;
      case chess_lib.PieceType.KNIGHT:
        _drawHorseKnight(canvas, size, center, iconR, iconFill, iconStroke, accent);
        break;
      case chess_lib.PieceType.PAWN:
        _drawSakuraPetalPawn(canvas, center, iconR * 0.82, iconFill, iconStroke);
        break;
    }
  }

  // ─── King: Chrysanthemum (Imperial Mon) ──────────────────────────────────
  void _drawLotusKing(Canvas canvas, Offset c, double r, Paint fill, Paint stroke, Color accent, bool white) {
    // 16-petal chrysanthemum (kiku) — imperial symbol
    const petals = 16;
    for (int i = 0; i < petals; i++) {
      final angle = (2 * pi / petals) * i - pi / 2;
      final tip = Offset(c.dx + cos(angle) * r, c.dy + sin(angle) * r);
      final base1 = Offset(
        c.dx + cos(angle - pi / petals) * r * 0.44,
        c.dy + sin(angle - pi / petals) * r * 0.44,
      );
      final base2 = Offset(
        c.dx + cos(angle + pi / petals) * r * 0.44,
        c.dy + sin(angle + pi / petals) * r * 0.44,
      );
      final petal = Path()
        ..moveTo(base1.dx, base1.dy)
        ..quadraticBezierTo(tip.dx, tip.dy, base2.dx, base2.dy)
        ..quadraticBezierTo(c.dx + cos(angle) * r * 0.2, c.dy + sin(angle) * r * 0.2, base1.dx, base1.dy)
        ..close();
      canvas.drawPath(petal, fill);
    }
    // Center disc
    canvas.drawCircle(c, r * 0.32, fill);
    canvas.drawCircle(c, r * 0.18,
        Paint()..style = PaintingStyle.fill..color = white ? const Color(0xFF7B0E06) : const Color(0xFF8C6A00));
    // Outer ring stroke
    canvas.drawCircle(c, r, stroke..strokeWidth *= 0.5);
    canvas.drawCircle(c, r * 0.32, stroke);
  }

  // ─── Queen: Five-Petal Ume (Plum Blossom) ────────────────────────────────
  void _drawPlumBlossomQueen(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    const petals = 5;
    for (int i = 0; i < petals; i++) {
      final angle = (2 * pi / petals) * i - pi / 2;
      final pc = Offset(c.dx + cos(angle) * r * 0.58, c.dy + sin(angle) * r * 0.58);
      canvas.drawCircle(pc, r * 0.40, fill);
    }
    // Center
    canvas.drawCircle(c, r * 0.28, fill);
    // Stamens — 5 dots radiating outward from center
    for (int i = 0; i < petals; i++) {
      final angle = (2 * pi / petals) * i - pi / 2;
      final dot = Offset(c.dx + cos(angle) * r * 0.20, c.dy + sin(angle) * r * 0.20);
      canvas.drawCircle(dot, r * 0.06,
          Paint()..style = PaintingStyle.fill..color = stroke.color.withValues(alpha: 0.90));
    }
    canvas.drawCircle(c, r, stroke..strokeWidth *= 0.45);
  }

  // ─── Rook: Torii Gate ─────────────────────────────────────────────────────
  void _drawToriiRook(Canvas canvas, Size size, Offset c, double r, Paint fill, Paint dim, Paint stroke) {
    final sw = r * 2;        // icon width
    final sh = r * 2;        // icon height
    final left  = c.dx - sw * 0.50;
    final right = c.dx + sw * 0.50;
    final top   = c.dy - sh * 0.50;
    final bot   = c.dy + sh * 0.50;

    // Kasagi (top crossbeam — upward-curving)
    final kasagi = Path()
      ..moveTo(left - sw * 0.06, top + sh * 0.10)
      ..quadraticBezierTo(c.dx, top - sh * 0.08, right + sw * 0.06, top + sh * 0.10)
      ..lineTo(right + sw * 0.06, top + sh * 0.22)
      ..quadraticBezierTo(c.dx, top + sh * 0.05, left - sw * 0.06, top + sh * 0.22)
      ..close();
    canvas.drawPath(kasagi, fill);

    // Nuki (lower horizontal rail)
    final nuki = Rect.fromCenter(
      center: Offset(c.dx, top + sh * 0.44),
      width: sw * 1.02,
      height: sh * 0.13,
    );
    canvas.drawRect(nuki, fill);

    // Left pillar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left + sw * 0.04, top + sh * 0.15, left + sw * 0.21, bot),
        const Radius.circular(2),
      ),
      fill,
    );

    // Right pillar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(right - sw * 0.21, top + sh * 0.15, right - sw * 0.04, bot),
        const Radius.circular(2),
      ),
      fill,
    );

    // Stroke outline all
    final toriiOutline = Path()
      ..moveTo(left - sw * 0.06, top + sh * 0.10)
      ..quadraticBezierTo(c.dx, top - sh * 0.08, right + sw * 0.06, top + sh * 0.10)
      ..lineTo(right + sw * 0.06, top + sh * 0.22)
      ..quadraticBezierTo(c.dx, top + sh * 0.05, left - sw * 0.06, top + sh * 0.22)
      ..close();
    canvas.drawPath(toriiOutline, stroke..strokeWidth = size.width * 0.018);
    canvas.drawRect(nuki, stroke);
  }

  // ─── Bishop: Enso + Diamond (Zen Circle) ─────────────────────────────────
  void _drawDiamondBishop(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    // Enso (open circle) — Zen Buddhism symbol
    canvas.drawArc(
      Rect.fromCenter(center: c, width: r * 2, height: r * 2),
      pi * 0.15,
      pi * 1.75,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.35
        ..strokeCap = StrokeCap.round
        ..color = fill.color,
    );

    // Inner diamond
    final dia = Path()
      ..moveTo(c.dx, c.dy - r * 0.38)
      ..lineTo(c.dx + r * 0.28, c.dy)
      ..lineTo(c.dx, c.dy + r * 0.38)
      ..lineTo(c.dx - r * 0.28, c.dy)
      ..close();
    canvas.drawPath(dia, fill);
    canvas.drawPath(dia, stroke..strokeWidth *= 0.5);
  }

  // ─── Knight: Stylized Horse Head (Uma) ───────────────────────────────────
  void _drawHorseKnight(Canvas canvas, Size size, Offset c, double r, Paint fill, Paint stroke, Color accent) {
    final top   = c.dy - r;
    final bot   = c.dy + r;

    // Neck / body block
    final head = Path()
      ..moveTo(c.dx - r * 0.55, bot)
      ..lineTo(c.dx - r * 0.45, c.dy + r * 0.10)
      ..quadraticBezierTo(c.dx - r * 0.50, c.dy - r * 0.30, c.dx - r * 0.20, c.dy - r * 0.58)
      ..quadraticBezierTo(c.dx + r * 0.10, top, c.dx + r * 0.35, c.dy - r * 0.70)
      ..lineTo(c.dx + r * 0.55, c.dy - r * 0.45)
      ..quadraticBezierTo(c.dx + r * 0.30, c.dy - r * 0.30, c.dx + r * 0.35, c.dy)
      ..lineTo(c.dx + r * 0.55, bot)
      ..close();
    canvas.drawPath(head, fill);
    canvas.drawPath(head, stroke..strokeWidth = size.width * 0.020);

    // Mane stripe
    final mane = Path()
      ..moveTo(c.dx - r * 0.22, c.dy - r * 0.56)
      ..quadraticBezierTo(c.dx + r * 0.05, c.dy - r * 0.20, c.dx + r * 0.30, c.dy - r * 0.10)
      ..lineTo(c.dx + r * 0.40, c.dy - r * 0.20)
      ..quadraticBezierTo(c.dx + r * 0.10, c.dy - r * 0.30, c.dx - r * 0.10, c.dy - r * 0.70)
      ..close();
    canvas.drawPath(mane,
        Paint()..style = PaintingStyle.fill..color = stroke.color.withValues(alpha: 0.55));

    // Eye
    canvas.drawCircle(
      Offset(c.dx + r * 0.16, c.dy - r * 0.55),
      r * 0.10,
      Paint()..style = PaintingStyle.fill..color = stroke.color,
    );
  }

  // ─── Pawn: Four-Petal Sakura (Cherry Blossom) ────────────────────────────
  void _drawSakuraPetalPawn(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    // Four rounded petals at N/S/E/W
    const petals = 4;
    for (int i = 0; i < petals; i++) {
      final angle = (2 * pi / petals) * i - pi / 4;
      final pc = Offset(c.dx + cos(angle) * r * 0.52, c.dy + sin(angle) * r * 0.52);
      canvas.drawCircle(pc, r * 0.46, fill);
    }
    // Center
    canvas.drawCircle(c, r * 0.30, fill);

    // Petal notch lines (characteristic sakura petal split at tip)
    for (int i = 0; i < petals; i++) {
      final angle = (2 * pi / petals) * i - pi / 4;
      final tip = Offset(c.dx + cos(angle) * r * 0.96, c.dy + sin(angle) * r * 0.96);
      canvas.drawLine(
        Offset(c.dx + cos(angle) * r * 0.60, c.dy + sin(angle) * r * 0.60),
        tip,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke.strokeWidth * 0.55
          ..strokeCap = StrokeCap.round
          ..color = stroke.color.withValues(alpha: 0.65),
      );
    }

    // Pistil center dot
    canvas.drawCircle(
      c,
      r * 0.12,
      Paint()..style = PaintingStyle.fill..color = stroke.color.withValues(alpha: 0.85),
    );
    canvas.drawCircle(c, r, stroke..strokeWidth *= 0.40);
  }

  @override
  bool shouldRepaint(covariant SakuraPiecePainter old) =>
      old.type != type || old.isWhite != isWhite || old.isHighlighted != isHighlighted;
}
