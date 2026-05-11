import 'package:flutter/material.dart';
import 'chess_theme.dart';

import '../widgets/grease_theme.dart';
import '../widgets/grease_effects.dart';

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
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (!animationsEnabled) return const SizedBox.shrink();
    return const IndustrialAtmosphereOverlay();
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
        painter: IndustrialPiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
          rotation: animationValue, // Re-using animationValue for rotation if needed
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return OilPuddleIndicator(isEnemy: isEnemy);
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return CustomPaint(
      painter: GreaseSelectionPainter(animationValue: animationValue),
      size: Size.infinite,
    );
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
