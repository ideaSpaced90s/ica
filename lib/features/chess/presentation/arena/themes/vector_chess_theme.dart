import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../shared/themes/chess_theme.dart';
import '../effects/walnut_piece_painter.dart';
import '../effects/sakura_piece_painter.dart';
import 'package:chess/chess.dart' as chess_lib;


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
    if (id == 'vector_sakura') {
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
        default:
          pType = chess_lib.PieceType.PAWN;
          break;
      }
      return AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: SakuraPiecePainter(
            type: pType,
            isWhite: isWhite,
            isHighlighted: isHighlighted,
          ),
        ),
      );
    }

    if (id == 'vector_egyptian') {
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
        default:
          pType = chess_lib.PieceType.PAWN;
          break;
      }
      return AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: WalnutPiecePainter(
            type: pType,
            isWhite: isWhite,
            isHighlighted: isHighlighted,
          ),
        ),
      );
    }

    if (id == 'vector_steel') {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Image.asset(
          _fairytalePiecePath(type, isWhite),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    if (id == 'vector_glass' || id == 'vector_championship') {
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
        default:
          colIndex = 5;
          break;
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
              'assets/board/ideaspaceclassicchesssprite2.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );
    }

    final pieceType = _mapPieceType(type);
    final pieceColor = isWhite ? assets_lib.ChessPieceColor.white : assets_lib.ChessPieceColor.black;

    return assets_lib.ChessPieceWidget(
      type: pieceType,
      color: pieceColor,
      theme: packageTheme,
      size: 48.0,
    );
  }

  String _fairytalePiecePath(String type, bool isWhite) {
    final colorStr = isWhite ? 'white' : 'black';
    String typeStr;
    switch (type.toUpperCase()) {
      case 'K': typeStr = 'king'; break;
      case 'Q': typeStr = 'queen'; break;
      case 'B': typeStr = 'bishop'; break;
      case 'N': typeStr = 'knight'; break;
      case 'R': typeStr = 'rook'; break;
      case 'P':
      default:
        typeStr = 'pawn_hammer';
        break;
    }
    return 'assets/pieces/fairytale_castle/${colorStr}_$typeStr.png';
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
