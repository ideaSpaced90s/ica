import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../widgets/ink_theme.dart';

class InkTheme extends ChessTheme {
  const InkTheme() : super(id: 'theme3', name: 'Ink Calligraphy');

  @override
  Color get lightSquare => const Color(0xFFF5F5DC);

  @override
  Color get darkSquare => const Color(0xFFD6D3D1);

  @override
  Color get frameColor => const Color(0xFF2C2C2C);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const Stack(
      children: [
        Positioned.fill(child: InkCheckSlash()),
      ],
    );
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const Positioned.fill(child: InkCheckSlash());
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return InkBoardPainter(isLight: isLight);
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
        painter: BrushStrokePiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return InkMoveHint(isEnemy: isEnemy);
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const InkRippleIndicator(isActive: true);
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
