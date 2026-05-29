import 'package:flutter/material.dart';
import '../../shared/themes/chess_theme.dart';
import '../effects/toy_effects.dart';
import '../effects/cartoon_toy_painter.dart';

class ToyTheme extends ChessTheme {
  const ToyTheme() : super(id: 'theme9', name: 'Mummy');

  @override
  Color get lightSquare => const Color(0xFFFFF3E0);

  @override
  Color get darkSquare => const Color(0xFFFFB74D);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get frameColor => const Color(0xFFE65100);

  @override
  BorderRadius get squareBorderRadius => BorderRadius.circular(10);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (!animationsEnabled) return const SizedBox.shrink();
    return const FloatingBubblesOverlay();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00BFFF).withValues(alpha: 0.5),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFFF).withValues(alpha: 0.3),
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
    return null;
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
        painter: CartoonToyPiecePainter(
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
              : const Color(
                  0xFF0D6EFD,
                ).withValues(alpha: 0.75), // Use scholarly blue for now
          border: isEnemy
              ? Border.all(color: const Color(0xFF0D6EFD), width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const SizedBox.shrink();
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
