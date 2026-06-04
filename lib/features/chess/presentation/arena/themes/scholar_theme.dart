import 'package:flutter/material.dart';
import '../../shared/themes/chess_theme.dart';

class ScholarTheme extends ChessTheme {
  const ScholarTheme() : super(id: 'scholar', name: 'Scholar');

  @override
  bool get hasInteractionFeedback => false;

  @override
  bool get hasSystemIndicators => false;

  @override
  bool get hasSFX => false;

  @override
  bool get isInstantMovements => true;

  @override
  Color get lightSquare => const Color(0xFFFDF6E2); // Cream

  @override
  Color get darkSquare => const Color(0xFF7BCBFC); // Sky Blue

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => const Color(0xFF0F172A).withValues(alpha: 0.8);

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
    return const SizedBox.shrink();
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
