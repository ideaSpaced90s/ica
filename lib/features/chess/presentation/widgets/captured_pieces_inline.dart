import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../arena/themes/theme_registry.dart';
import '../scholarly_theme.dart';

import '../battleground/themes/rated_bnw_theme.dart';

class CapturedPiecesInline extends ConsumerWidget {
  final List<chess_lib.Piece> pieces;
  final List<chess_lib.Piece> opponentPieces;
  final bool useBnwTheme;

  const CapturedPiecesInline({
    super.key,
    required this.pieces,
    this.opponentPieces = const [],
    this.useBnwTheme = false,
  });

  int _getPieceValue(chess_lib.PieceType type) {
    if (type == chess_lib.PieceType.PAWN) return 1;
    if (type == chess_lib.PieceType.KNIGHT) return 3;
    if (type == chess_lib.PieceType.BISHOP) return 3;
    if (type == chess_lib.PieceType.ROOK) return 5;
    if (type == chess_lib.PieceType.QUEEN) return 9;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pieces.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = useBnwTheme
        ? ratedBnwTheme
        : () {
            final chessState = ref.watch(chessProvider);
            final themeId = ThemeRegistry.resolveThemeId(chessState);
            return ThemeRegistry.getTheme(themeId);
          }();

    // Sort pieces by value
    final sortedPieces = List<chess_lib.Piece>.from(pieces)
      ..sort((a, b) => _getPieceValue(a.type).compareTo(_getPieceValue(b.type)));

    final totalSelfValue = pieces.fold<int>(0, (sum, piece) => sum + _getPieceValue(piece.type));
    final totalOpponentValue = opponentPieces.fold<int>(0, (sum, piece) => sum + _getPieceValue(piece.type));
    final scoreDiff = totalSelfValue - totalOpponentValue;

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
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...sortedPieces.map((piece) {
            final type = piece.type.toString().toUpperCase();
            final isWhite = piece.color == chess_lib.Color.WHITE;

            return SizedBox(
              width: 22,
              height: 22,
              child: theme.buildPiece(context, type, isWhite, false, 0.0),
            );
          }),
          if (scoreDiff > 0)
            Padding(
              padding: const EdgeInsets.only(left: 14), // offset the negative spacing of -6 and leave a nice gap
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.realGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ScholarlyTheme.realGold.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.realGold.withValues(alpha: 0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  '+$scoreDiff',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.realGold,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
