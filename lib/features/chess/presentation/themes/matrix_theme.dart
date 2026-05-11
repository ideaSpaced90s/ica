import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../widgets/matrix_effects.dart';
import '../widgets/matrix_theme_painter.dart';
import '../widgets/matrix_piece_painter.dart';

class MatrixTheme extends ChessTheme {
  const MatrixTheme() : super(id: 'theme6', name: 'Matrix');

  @override
  Color get lightSquare => const Color(0xFF1A1A1A);

  @override
  Color get darkSquare => const Color(0xFF000000);

  @override
  Color get lightCoordinateColor => Colors.greenAccent.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.greenAccent.withValues(alpha: 0.7);

  @override
  Color get frameColor => const Color(0xFF000000);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (!animationsEnabled) return const SizedBox.shrink();
    return const Stack(
      children: [
        MatrixFallingCodeOverlay(),
        ScanlineOverlay(),
      ],
    );
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const Positioned.fill(child: MatrixCheckRedPulse());
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return MatrixSquarePainter(
      isLight: isLight,
      animationValue: animationValue,
    );
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
        painter: MatrixPiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
          isHighlighted: isHighlighted,
          animationValue: animationValue,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return CustomPaint(
      painter: MatrixMoveHintPainter(animationValue: 0.0), // Placeholder
      size: Size.square(isEnemy ? 45 : 20),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return CustomPaint(
      painter: DigitalPulsePainter(
        animationValue: animationValue,
        color: Colors.white,
      ),
      size: Size.infinite,
    );
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
