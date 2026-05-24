import 'package:flutter/material.dart';
import 'chess_theme.dart';

class ScholarTheme extends ChessTheme {
  const ScholarTheme() : super(id: 'scholar', name: 'Scholar');

  @override
  Color get lightSquare => const Color(0xFFF0F2F5); // Soft White

  @override
  Color get darkSquare => const Color(0xFF1E3A8A); // Navy Blue

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF0F172A); // Darker Slate/Navy Frame

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const SizedBox.shrink();
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
    final colorPrefix = isWhite ? 'w' : 'b';
    String pieceName;
    
    switch (type.toUpperCase()) {
      case 'K':
        pieceName = 'King';
        break;
      case 'Q':
        pieceName = 'Queen';
        break;
      case 'B':
        pieceName = 'Bishop';
        break;
      case 'N':
        pieceName = 'Knight';
        break;
      case 'R':
        pieceName = 'Rook';
        break;
      case 'P':
        pieceName = 'Pawn';
        break;
      default:
        pieceName = 'Pawn';
    }
    
    return Padding(
      padding: const EdgeInsets.all(4.0), // give it a little breathing room
      child: Image.asset(
        'assets/board/scholar_pieces/${pieceName}_$colorPrefix.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
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
              : const Color(0xFF0D6EFD).withValues(alpha: 0.75),
          border: isEnemy
              ? Border.all(color: const Color(0xFF0D6EFD), width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    // Standard gold star animation or similar
    return const SizedBox.shrink(); // Will be handled by the default OrbitingStar
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0056B3).withValues(alpha: opacity),
      ),
    );
  }
}
