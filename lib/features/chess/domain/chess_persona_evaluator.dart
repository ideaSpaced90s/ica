import 'package:kingslayer_chess/src/rust/api/persona.dart' as rust_persona;
import '../domain/chess_game.dart';
import '../domain/models/ai_avatar.dart';
import '../domain/models/candidate_move.dart';

class ChessPersonaEvaluator {
  static String selectBestMove(
    List<CandidateMove> candidates,
    AiAvatar avatar,
    ChessGame game,
    String defaultBestMove,
  ) {
    if (candidates.isEmpty) return defaultBestMove;
    if (avatar.name == 'King' || avatar.name == 'Kingslayer') return defaultBestMove;

    try {
      final sortedCandidates = List<CandidateMove>.from(candidates)
        ..sort((a, b) => a.multipvIndex.compareTo(b.multipvIndex));

      final rustCandidates = sortedCandidates.map((c) {
        return rust_persona.PersonaCandidate(
          uciMove: c.uciMove,
          evaluation: c.evaluation,
        );
      }).toList();

      final selectedMove = rust_persona.selectPersonaMoveRust(
        fen: game.fen,
        candidates: rustCandidates,
        avatarName: avatar.name,
        isChess960: game.isChess960,
        moveCount: game.history.length,
      );

      if (selectedMove.isNotEmpty) {
        return selectedMove;
      }
    } catch (e) {
      // Silent fallback to default best move
    }

    return defaultBestMove;
  }
}
