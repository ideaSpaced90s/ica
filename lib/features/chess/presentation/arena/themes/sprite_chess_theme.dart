import 'package:flutter/material.dart';
import '../../shared/themes/chess_theme.dart';

class SpriteChessTheme extends ChessTheme {
  final String? spritePath;
  final String? individualPiecesFolder;
  @override
  final String? boardImagePath;
  @override
  final Color lightSquare;
  @override
  final Color darkSquare;
  @override
  final Color frameColor;

  const SpriteChessTheme({
    required super.id,
    required super.name,
    this.spritePath,
    this.individualPiecesFolder,
    this.boardImagePath,
    required this.lightSquare,
    required this.darkSquare,
    required this.frameColor,
  });

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (boardImagePath != null) {
      return Image.asset(
        boardImagePath!,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
      );
    }
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
    if (individualPiecesFolder != null) {
      final colorStr = id == 'sprite_fairytale'
          ? (isWhite ? 'white' : 'black')
          : (isWhite ? 'light' : 'dark');
      String typeStr;
      switch (type.toUpperCase()) {
        case 'K':
          typeStr = 'king';
          break;
        case 'Q':
          typeStr = 'queen';
          break;
        case 'B':
          typeStr = 'bishop';
          break;
        case 'N':
          typeStr = 'knight';
          break;
        case 'R':
          typeStr = 'rook';
          break;
        case 'P':
        default:
          typeStr = id == 'sprite_fairytale' ? 'pawn_hammer' : 'pawn';
          break;
      }
      return AspectRatio(
        aspectRatio: 1.0,
        child: Image.asset(
          '$individualPiecesFolder/${colorStr}_$typeStr.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    }

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
            spritePath ?? '',
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
