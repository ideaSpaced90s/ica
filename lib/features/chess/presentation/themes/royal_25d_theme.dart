import 'package:flutter/material.dart';
import 'chess_theme.dart';

class Royal25DTheme extends ChessTheme {
  const Royal25DTheme() : super(id: 'theme11', name: 'Royal 2.5D');

  @override
  Color get lightSquare => const Color(0xFFF8FAFC); // Clean White

  @override
  Color get darkSquare => const Color(0xFF38BDF8); // Vibrant Sky Blue

  @override
  Color get lightCoordinateColor => const Color(0xFF0284C7).withValues(alpha: 0.6);

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
    final rowIndex = isWhite ? 0 : 1;
    int colIndex;
    switch (type.toUpperCase()) {
      case 'K': colIndex = 0; break;
      case 'Q': colIndex = 1; break;
      case 'B': colIndex = 2; break;
      case 'N': colIndex = 3; break;
      case 'R': colIndex = 4; break;
      case 'P': colIndex = 5; break;
      default: colIndex = 5;
    }

    final horizontalShift = switch (type.toUpperCase()) {
      'Q' => -7.5,
      'B' => -5.0,
      'P' => 0.0, // Shifted right relative to other pieces
      _ => -2.5,
    };

    return AspectRatio(
      aspectRatio: 1,
      child: Transform.translate(
        offset: Offset(horizontalShift, -2.0), // Shift slightly left and up
        child: Transform.scale(
          scale: 0.95, // Reduced size by "one notch"
          child: ClipRect(
            child: FractionallySizedBox(
              widthFactor: 6.0,
              heightFactor: 2.0,
              alignment: Alignment(
                (colIndex * 2.0 / 5.0) - 1.0,
                (rowIndex * 2.0 / 1.0) - 1.0,
              ),
              child: Image.asset(
                'assets/board/pieces_25d.png',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
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
    return const SizedBox.shrink(); // Use default OrbitingStar
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
