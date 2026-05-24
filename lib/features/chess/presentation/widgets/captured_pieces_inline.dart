import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../application/chess_provider.dart';
import '../arena/themes/theme_registry.dart';
import '../scholarly_theme.dart';

class CapturedPiecesInline extends ConsumerWidget {
  final List<chess_lib.Piece> pieces;

  const CapturedPiecesInline({super.key, required this.pieces});

  int _getPieceValue(chess_lib.PieceType type) {
    if (type == chess_lib.PieceType.PAWN) return 1;
    if (type == chess_lib.PieceType.KNIGHT) return 3;
    if (type == chess_lib.PieceType.BISHOP) return 4;
    if (type == chess_lib.PieceType.ROOK) return 5;
    if (type == chess_lib.PieceType.QUEEN) return 9;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pieces.isEmpty) {
      return const SizedBox.shrink();
    }

    final chessState = ref.watch(chessProvider);
    final themeId = ThemeRegistry.resolveThemeId(chessState);
    final theme = ThemeRegistry.getTheme(themeId);

    // Sort pieces by value
    final sortedPieces = List<chess_lib.Piece>.from(pieces)
      ..sort((a, b) => _getPieceValue(a.type).compareTo(_getPieceValue(b.type)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: -6, // Stack overlap feel
        crossAxisAlignment: WrapCrossAlignment.center,
        children: sortedPieces.map((piece) {
          final type = piece.type.toString().toUpperCase();
          final isWhite = piece.color == chess_lib.Color.WHITE;

          return SizedBox(
            width: 24,
            height: 24,
            child: theme.buildPiece(context, type, isWhite, false, 0.0),
          );
        }).toList(),
      ),
    );
  }
}
