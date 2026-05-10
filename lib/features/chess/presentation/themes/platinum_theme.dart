import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../widgets/platinum_theme.dart';
import '../widgets/toy_effects.dart';
import 'package:chess/chess.dart' as chess_lib;

class PlatinumTheme extends ChessTheme {
  const PlatinumTheme() : super(id: 'theme4', name: 'Platinum Metallic');

  @override
  Color get lightSquare => const Color(0xFFD1D5DB);

  @override
  Color get darkSquare => const Color(0xFF374151);

  @override
  Color get frameColor => const Color(0xFF1F2933);

  @override
  BorderRadius get squareBorderRadius => BorderRadius.circular(10);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (!animationsEnabled) return const SizedBox.shrink();
    return const FloatingBubblesOverlay();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return PlatinumBoardPainter(
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
    chess_lib.PieceType pType;
    switch (type.toUpperCase()) {
      case 'K': pType = chess_lib.PieceType.KING; break;
      case 'Q': pType = chess_lib.PieceType.QUEEN; break;
      case 'R': pType = chess_lib.PieceType.ROOK; break;
      case 'B': pType = chess_lib.PieceType.BISHOP; break;
      case 'N': pType = chess_lib.PieceType.KNIGHT; break;
      case 'P': pType = chess_lib.PieceType.PAWN; break;
      default: pType = chess_lib.PieceType.PAWN;
    }
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: MetalPiecePainter(
          type: pType,
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
      painter: PlatinumMoveHintPainter(isEnemy: isEnemy),
      size: Size.infinite,
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return CustomPaint(
      painter: PlatinumSelectionPainter(
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
        color: const Color(0xFFFFD700).withValues(alpha: opacity),
      ),
    );
  }
}
