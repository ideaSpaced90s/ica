import 'package:flutter/material.dart';
import '../../shared/themes/chess_theme.dart';
import '../effects/slate_theme.dart';

class SlateTheme extends ChessTheme {
  const SlateTheme() : super(id: 'theme7', name: 'Slate');

  @override
  Color get lightSquare => const Color(0xFFE5E7EB);

  @override
  Color get darkSquare => const Color(0xFF374151);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF1F2937);

  @override
  BorderRadius get squareBorderRadius => BorderRadius.circular(12);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const Positioned.fill(child: SlateCheckBorder());
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
        painter: MinimalPiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return CustomPaint(
      painter: SlateMoveHintPainter(isEnemy: isEnemy),
      size: Size.infinite,
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const CustomPaint(
      painter: SlateSelectionPainter(),
      size: Size.infinite,
    );
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D6EFD).withValues(alpha: opacity),
      ),
    );
  }
}
