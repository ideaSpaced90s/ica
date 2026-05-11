import 'package:flutter/material.dart';
import 'chess_theme.dart';

import '../widgets/walnut_theme_painter.dart';
import '../widgets/walnut_piece_painter.dart';
import 'package:chess/chess.dart' as chess_lib;

class WalnutTheme extends ChessTheme {
  const WalnutTheme() : super(id: 'theme8', name: 'Walnut');

  @override
  Color get lightSquare => const Color(0xFFE6C9A8);

  @override
  Color get darkSquare => const Color(0xFF6B4F3A);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF4A3728);

  @override
  BorderRadius get squareBorderRadius => BorderRadius.circular(10);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (!animationsEnabled) return const SizedBox.shrink();
    return const InsetShadowOverlay();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return WalnutBoardPainter(
      isLight: isLight,
      baseColor: isLight ? lightSquare : darkSquare,
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
        painter: WalnutPiecePainter(
          type: pType,
          isWhite: isWhite,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 35 : 10,
        height: isEnemy ? 35 : 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy 
              ? Colors.transparent 
              : Colors.black.withValues(alpha: 0.3),
          border: isEnemy 
              ? Border.all(color: Colors.black.withValues(alpha: 0.3), width: 2.0)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const SizedBox.shrink(); // Walnut usually uses standard OrbitingStar or similar
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
