import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../shared/themes/chess_theme.dart';

class VectorChessTheme extends ChessTheme {
  final assets_lib.ChessTheme packageTheme;

  const VectorChessTheme({
    required super.id,
    required super.name,
    required this.packageTheme,
  });

  @override
  Color get lightSquare => packageTheme.lightSquare;

  @override
  Color get darkSquare => packageTheme.darkSquare;

  @override
  Color get lightCoordinateColor => packageTheme.darkSquare.withValues(alpha: 0.8);

  @override
  Color get darkCoordinateColor => packageTheme.lightSquare.withValues(alpha: 0.8);

  @override
  Color get frameColor => packageTheme.boardBorder;

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
    final pieceType = _mapPieceType(type);
    final pieceColor = isWhite ? assets_lib.ChessPieceColor.white : assets_lib.ChessPieceColor.black;

    return assets_lib.ChessPieceWidget(
      type: pieceType,
      color: pieceColor,
      theme: packageTheme,
      size: 48.0,
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
              : packageTheme.activeHighlight,
          border: isEnemy
              ? Border.all(color: packageTheme.activeHighlight, width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: packageTheme.activeHighlight, width: 3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: packageTheme.activeHighlight.withValues(alpha: opacity),
      ),
    );
  }

  assets_lib.ChessPieceType _mapPieceType(String type) {
    switch (type.toUpperCase()) {
      case 'K': return assets_lib.ChessPieceType.king;
      case 'Q': return assets_lib.ChessPieceType.queen;
      case 'R': return assets_lib.ChessPieceType.rook;
      case 'B': return assets_lib.ChessPieceType.bishop;
      case 'N': return assets_lib.ChessPieceType.knight;
      case 'P':
      default:
        return assets_lib.ChessPieceType.pawn;
    }
  }
}
