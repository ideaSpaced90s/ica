import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../scholarly_theme.dart';

class MiniBoardPreview extends StatelessWidget {
  final String fen;
  final double size;
  final bool isFlipped;

  const MiniBoardPreview({
    super.key,
    required this.fen,
    this.size = 120,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    final chess = chess_lib.Chess.fromFEN(fen);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemCount: 64,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final row = index ~/ 8;
          final col = index % 8;
          
          final displayRow = isFlipped ? 7 - row : row;
          final displayCol = isFlipped ? 7 - col : col;
          
          final isLight = (displayRow + displayCol) % 2 == 0;
          final squareName = _getSquareName(row, col, isFlipped);
          final piece = chess.get(squareName);

          return Container(
            color: isLight ? const Color(0xFFE2E8F0).withValues(alpha: 0.1) : const Color(0xFF1E293B).withValues(alpha: 0.3),
            child: piece != null ? _buildPiece(piece) : null,
          );
        },
      ),
    );
  }

  String _getSquareName(int row, int col, bool flipped) {
    final r = flipped ? row + 1 : 8 - row;
    final c = flipped ? 7 - col : col;
    return '${String.fromCharCode(97 + c)}$r';
  }

  Widget _buildPiece(chess_lib.Piece piece) {
    final colorPrefix = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final type = piece.type.toUpperCase();
    final assetPath = 'assets/pieces/$colorPrefix$type.svg';
    
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SvgPicture.asset(assetPath),
    );
  }
}
