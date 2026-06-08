import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../shared/themes/chess_theme.dart';

class AcademyChampionTheme extends ChessTheme {
  const AcademyChampionTheme() : super(id: 'academy_champion', name: 'Champions');

  @override
  Color get lightSquare => assets_lib.ChessThemes.championshipClassic.lightSquare;

  @override
  Color get darkSquare => assets_lib.ChessThemes.championshipClassic.darkSquare;

  @override
  Color get lightCoordinateColor => assets_lib.ChessThemes.championshipClassic.darkSquare.withValues(alpha: 0.8);

  @override
  Color get darkCoordinateColor => assets_lib.ChessThemes.championshipClassic.lightSquare.withValues(alpha: 0.8);

  @override
  Color get frameColor => assets_lib.ChessThemes.championshipClassic.boardBorder;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.5),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) => null;

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    final int rowIndex = isWhite ? 0 : 1;
    int colIndex = 0;
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
              : assets_lib.ChessThemes.championshipClassic.activeHighlight,
          border: isEnemy
              ? Border.all(color: assets_lib.ChessThemes.championshipClassic.activeHighlight, width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return DefaultSelectionRing(color: assets_lib.ChessThemes.championshipClassic.activeHighlight);
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: assets_lib.ChessThemes.championshipClassic.activeHighlight.withValues(alpha: opacity),
      ),
    );
  }
}

class DefaultSelectionRing extends StatelessWidget {
  final Color color;
  const DefaultSelectionRing({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3),
        shape: BoxShape.circle,
      ),
    );
  }
}
