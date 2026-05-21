import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../widgets/forest_effects.dart';
import '../widgets/forest_theme_painter.dart';

class ForestTheme extends ChessTheme {
  const ForestTheme() : super(id: 'theme2', name: 'Forest');

  @override
  Color get lightSquare => const Color(0xFFE6D3A3);

  @override
  Color get darkSquare => const Color(0xFF4F7942);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF2E4D23);

  @override
  BorderRadius get squareBorderRadius => BorderRadius.circular(10);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.5),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return LeafTexturePainter();
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
        painter: WoodenPiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 38 : 12,
        height: isEnemy ? 38 : 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy
              ? Colors.transparent
              : const Color(0xFFE7F1FF).withValues(alpha: 0.75),
          border: isEnemy
              ? Border.all(color: const Color(0xFFE7F1FF), width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const SelectionGlowRing(isActive: true);
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
