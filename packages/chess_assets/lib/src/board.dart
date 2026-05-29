import 'package:flutter/material.dart';
import 'models.dart';
import '../themes/themes.dart';
import '../pieces/pieces.dart';

class ChessBoardWidget extends StatelessWidget {
  final ChessTheme theme;
  final Map<String, ChessPieceData> initialSetup;
  final String? activeSquare; // Example: 'e4'

  const ChessBoardWidget({
    super.key,
    required this.theme,
    this.initialSetup = const {},
    this.activeSquare,
  });

  static Map<String, ChessPieceData> get defaultSetup {
    final setup = <String, ChessPieceData>{};
    
    // Pawns
    for (int i = 0; i < 8; i++) {
      setup['${String.fromCharCode(97 + i)}2'] = ChessPieceData(ChessPieceType.pawn, ChessPieceColor.white);
      setup['${String.fromCharCode(97 + i)}7'] = ChessPieceData(ChessPieceType.pawn, ChessPieceColor.black);
    }

    // Rooks
    setup['a1'] = ChessPieceData(ChessPieceType.rook, ChessPieceColor.white);
    setup['h1'] = ChessPieceData(ChessPieceType.rook, ChessPieceColor.white);
    setup['a8'] = ChessPieceData(ChessPieceType.rook, ChessPieceColor.black);
    setup['h8'] = ChessPieceData(ChessPieceType.rook, ChessPieceColor.black);

    // Knights
    setup['b1'] = ChessPieceData(ChessPieceType.knight, ChessPieceColor.white);
    setup['g1'] = ChessPieceData(ChessPieceType.knight, ChessPieceColor.white);
    setup['b8'] = ChessPieceData(ChessPieceType.knight, ChessPieceColor.black);
    setup['g8'] = ChessPieceData(ChessPieceType.knight, ChessPieceColor.black);

    // Bishops
    setup['c1'] = ChessPieceData(ChessPieceType.bishop, ChessPieceColor.white);
    setup['f1'] = ChessPieceData(ChessPieceType.bishop, ChessPieceColor.white);
    setup['c8'] = ChessPieceData(ChessPieceType.bishop, ChessPieceColor.black);
    setup['f8'] = ChessPieceData(ChessPieceType.bishop, ChessPieceColor.black);

    // Queens
    setup['d1'] = ChessPieceData(ChessPieceType.queen, ChessPieceColor.white);
    setup['d8'] = ChessPieceData(ChessPieceType.queen, ChessPieceColor.black);

    // Kings
    setup['e1'] = ChessPieceData(ChessPieceType.king, ChessPieceColor.white);
    setup['e8'] = ChessPieceData(ChessPieceType.king, ChessPieceColor.black);

    return setup;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.boardBorder, width: 4.0),
        ),
        child: Column(
          children: List.generate(8, (row) {
            return Expanded(
              child: Row(
                children: List.generate(8, (col) {
                  final isLightSquare = (row + col) % 2 == 0;
                  final squareColor = isLightSquare ? theme.lightSquare : theme.darkSquare;
                  
                  // standard algebraic notation (e.g. 'e4')
                  // row 0 is rank 8 (top of board), row 7 is rank 1 (bottom of board)
                  final rank = 8 - row;
                  final file = String.fromCharCode(97 + col); 
                  final squareName = '$file$rank';
                  
                  final pieceData = initialSetup.isNotEmpty ? initialSetup[squareName] : defaultSetup[squareName];
                  final isHighlighted = squareName == activeSquare;

                  return Expanded(
                    child: Container(
                      color: isHighlighted ? theme.activeHighlight : squareColor,
                      child: pieceData != null
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                // Make the piece slightly smaller than the square
                                final pieceSize = constraints.maxWidth * 0.8;
                                return Center(
                                  child: ChessPieceWidget(
                                    type: pieceData.type,
                                    color: pieceData.color,
                                    theme: theme,
                                    size: pieceSize,
                                  ),
                                );
                              },
                            )
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class ChessPieceData {
  final ChessPieceType type;
  final ChessPieceColor color;

  ChessPieceData(this.type, this.color);
}
