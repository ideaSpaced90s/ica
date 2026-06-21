import 'package:flutter/material.dart';
import '../../shared/themes/chess_theme.dart';

class AcademyBnwTheme extends ChessTheme {
  const AcademyBnwTheme() : super(id: 'theme10', name: 'Black & White');

  @override
  Color get lightSquare => const Color(0xFFEEEEEE); // Light grey/white

  @override
  Color get darkSquare => const Color(0xFF4A4A4A); // Dark charcoal

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF212121);

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
    final rowIndex = isWhite ? 0 : 1;
    int colIndex;
    switch (type.toUpperCase()) {
      case 'K':
        colIndex = 0;
        break;
      case 'Q':
        colIndex = 1;
        break;
      case 'B':
        colIndex = 2;
        break;
      case 'N':
        colIndex = 3;
        break;
      case 'R':
        colIndex = 4;
        break;
      case 'P':
        colIndex = 5;
        break;
      default:
        colIndex = 5;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRect(
        child: FractionallySizedBox(
          widthFactor: 6.0,
          heightFactor: 2.0,
          alignment: Alignment(
            (colIndex * 2.0 / 5.0) - 1.0,
            (rowIndex * 2.0 / 1.0) - 1.0,
          ),
          child: Image.asset(
            'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
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
              : const Color(0xFF757575).withValues(alpha: 0.75),
          border: isEnemy
              ? Border.all(color: const Color(0xFF757575), width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF9E9E9E).withValues(alpha: opacity),
      ),
    );
  }
}
