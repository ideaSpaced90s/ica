import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chess_board.dart';
import '../../application/chess_provider.dart';
import 'captured_pieces_bar.dart';

class BoardStage extends ConsumerWidget {
  const BoardStage({super.key, this.isExpanded = false});

  final bool isExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final isFlipped = state.isBoardFlipped;

    final capturedByWhite = state.game.capturedByWhite;
    final capturedByBlack = state.game.capturedByBlack;

    // Logic: Bottom player captures go to the bottom bar.
    // If not flipped: White is bottom. Bottom bar shows pieces captured BY White (Black pieces).
    // If flipped: Black is bottom. Bottom bar shows pieces captured BY Black (White pieces).

    final topPieces = isFlipped ? capturedByWhite : capturedByBlack;
    final bottomPieces = isFlipped ? capturedByBlack : capturedByWhite;

    return Column(
      mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        if (!isExpanded) CapturedPiecesBar(pieces: topPieces),
        Expanded(
          child: Align(
            alignment: isExpanded ? Alignment.topCenter : Alignment.center,
            child: ChessBoard(
              alignment: isExpanded ? Alignment.topCenter : Alignment.center,
            ),
          ),
        ),
        if (!isExpanded) CapturedPiecesBar(pieces: bottomPieces),
      ],
    );
  }
}
