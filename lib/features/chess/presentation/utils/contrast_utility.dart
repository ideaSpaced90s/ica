import 'package:flutter/material.dart';

class ContrastUtility {
  // Board Colors
  static const Color pureDarkBase = Color(0xFF000000);
  static const Color lightSquare = Color(0xFF3C3C3C);
  static const Color darkSquare = Color(0xFF000000);
  static const Color gridLine = Color(0xFF2A2A2A);

  // Piece Colors
  static const Color whitePieceFill = Color(0xFFFFFFFF);
  static const Color blackPieceFill = Color(0xFF121212);

  // Interaction
  static const Color selectionGlow = Color(0xFFFFFFFF);
  static const Color validMoveDot = Color(0xCCFFFFFF); // 80% opacity
  static const Color selectionRing = Color(0xFFFFFFFF);

  static Color getPieceFill(bool isWhite) =>
      isWhite ? whitePieceFill : blackPieceFill;

  static Color getStrokeColor(bool isWhite) =>
      isWhite ? Colors.black : Colors.white;

  static List<BoxShadow> getPieceShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.6),
        blurRadius: 8,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
    ];
  }

  static Paint getRimLightPaint(Rect rect) {
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white.withValues(alpha: 0.25), Colors.transparent],
        stops: const [0.0, 0.4],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
  }

  static Paint getInnerGradientPaint(Rect rect, bool isWhite) {
    final baseColor = getPieceFill(isWhite);
    return Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.3),
        radius: 0.8,
        colors: [isWhite ? Colors.white : const Color(0xFF333333), baseColor],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
  }
}
