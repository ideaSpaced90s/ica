import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../application/chess_provider.dart';
import '../arena/themes/theme_registry.dart';
import '../scholarly_theme.dart';

class CapturedPiecesBar extends ConsumerWidget {
  final List<chess_lib.Piece> pieces;

  const CapturedPiecesBar({super.key, required this.pieces});

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
    // We return a sized box even if empty to maintain layout stability during gameplay
    if (pieces.isEmpty) {
      return const SizedBox(height: 48);
    }

    final chessState = ref.watch(chessProvider);
    final themeId = ThemeRegistry.resolveThemeId(chessState);
    final theme = ThemeRegistry.getTheme(themeId);

    // Sort pieces by value
    final sortedPieces = List<chess_lib.Piece>.from(
      pieces,
    )..sort((a, b) => _getPieceValue(a.type).compareTo(_getPieceValue(b.type)));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: -6, // Subtle overlap for a "stacked" feel
        runSpacing: 4,
        children: sortedPieces.map((piece) {
          final type = piece.type.toString().toUpperCase();
          final isWhite = piece.color == chess_lib.Color.WHITE;

          return SizedBox(
            width: 36,
            height: 36,
            child: theme.buildPiece(context, type, isWhite, false, 0.0),
          );
        }).toList(),
      ),
    );
  }
}
