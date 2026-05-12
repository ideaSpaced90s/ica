import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'chess_theme.dart';
import '../widgets/royal_piece_painter.dart';

class Royal25DTheme extends ChessTheme {
  const Royal25DTheme() : super(id: 'theme11', name: 'Royal');

  @override
  Color get lightSquare => const Color(0xFFF8FAFC); // Clean White

  @override
  Color get darkSquare => const Color(0xFF38BDF8); // Vibrant Sky Blue

  @override
  Color get lightCoordinateColor =>
      const Color(0xFF0284C7).withValues(alpha: 0.6);

  @override
  Color get darkCoordinateColor => Colors.white.withValues(alpha: 0.6);

  @override
  Color get frameColor => const Color(0xFF111827);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F172A),
            const Color(0xFF38BDF8).withValues(alpha: 0.15),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
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
    chess_lib.PieceType pType;
    switch (type.toUpperCase()) {
      case 'K':
        pType = chess_lib.PieceType.KING;
        break;
      case 'Q':
        pType = chess_lib.PieceType.QUEEN;
        break;
      case 'R':
        pType = chess_lib.PieceType.ROOK;
        break;
      case 'B':
        pType = chess_lib.PieceType.BISHOP;
        break;
      case 'N':
        pType = chess_lib.PieceType.KNIGHT;
        break;
      case 'P':
        pType = chess_lib.PieceType.PAWN;
        break;
      default:
        pType = chess_lib.PieceType.PAWN;
    }

    return RoyalVectorPiece(
      type: pType,
      isWhite: isWhite,
      isHighlighted: isHighlighted,
      animationValue: animationValue,
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 42 : 16,
        height: isEnemy ? 42 : 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy
              ? Colors.transparent
              : const Color(0xFFFACC15).withValues(alpha: 0.4),
          border: isEnemy
              ? Border.all(color: const Color(0xFFFACC15), width: 3)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return CustomPaint(
      painter: RoyalSelectionPainter(animationValue: animationValue),
      size: Size.infinite,
    );
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15).withValues(alpha: opacity * 0.4),
      ),
    );
  }
}
