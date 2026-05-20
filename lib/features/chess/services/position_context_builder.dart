import 'package:flutter/foundation.dart';
import 'package:kingslayer_chess/src/rust/api/context.dart';
import 'package:kingslayer_chess/src/rust/api/humanizer.dart';
import 'package:kingslayer_chess/src/rust/api/threats.dart';
import '../domain/chess_game.dart';
import '../domain/models/position_context.dart';
import '../domain/models/candidate_move.dart';

class PositionContextBuilder {
  static PositionContext build({
    required String move,
    required double currentEval,
    required double previousEval,
    required ChessGame game,
    String? bestMove,
    List<String> pvLine = const [],
    List<CandidateMove> candidates = const [],
  }) {
    final evalDiff = currentEval - previousEval;
    final quality = _classifyQuality(evalDiff);
    final gamePhase = _detectGamePhase(game);

    // Compute FEN before the move
    String fenBefore = game.fen;
    if (game.history.isNotEmpty) {
      try {
        final temp = ChessGame(fen: game.fen, isChess960: game.isChess960);
        temp.undo();
        fenBefore = temp.fen;
      } catch (e) {
        debugPrint('ContextBuilder: Error calculating FEN before move: $e');
      }
    }

    // Call Rust humanizer and tactical scan
    String moveDescription = move;
    try {
      moveDescription = humanizeMoveRust(fenBefore: fenBefore, moveUci: move);
    } catch (e) {
      debugPrint('ContextBuilder: Error calling humanizeMoveRust: $e');
    }

    List<String> tacticalThreats = [];
    try {
      tacticalThreats = analyzeTacticalThreats(fen: game.fen);
    } catch (e) {
      debugPrint('ContextBuilder: Error calling analyzeTacticalThreats: $e');
    }

    final isBestMove = _compareMoves(move, bestMove);
    final threatLevel = _calculateThreatLevel(evalDiff, pvLine);
    final positionStyle = _determinePositionStyle(move, tacticalThreats, evalDiff);

    return PositionContext(
      move: move,
      moveDescription: moveDescription,
      evaluation: currentEval,
      evalDiff: evalDiff,
      quality: quality,
      bestMove: bestMove,
      isBestMove: isBestMove,
      gamePhase: gamePhase,
      tacticalThreats: tacticalThreats,
      threatLevel: threatLevel,
      positionStyle: positionStyle,
      pvLine: pvLine,
      candidates: candidates,
    );
  }

  static String _classifyQuality(double diff) {
    if (diff > 1.5) return 'Brilliant';
    if (diff > 0.5) return 'Strong';
    if (diff > -0.5) return 'Neutral';
    if (diff > -1.5) return 'Inaccuracy';
    return 'Blunder';
  }

  static String _detectGamePhase(ChessGame game) {
    try {
      final metrics = evaluatePositionMetrics(
        fen: game.fen,
        historyLength: game.history.length,
      );
      return metrics.gamePhase;
    } catch (e) {
      debugPrint('Rust Context Engine Error: $e');
    }

    // Safe fallback
    final moveCount = game.history.length;
    if (moveCount <= 20) return 'Opening';
    return 'Middlegame';
  }

  static bool _compareMoves(String played, String? best) {
    if (best == null) return false;
    // Normalize both to uci if they aren't already
    // played is usually like "e2e4", best is "e2e4"
    return played.replaceAll('-', '').replaceAll(' ', '') ==
        best.replaceAll('-', '').replaceAll(' ', '');
  }

  static String _calculateThreatLevel(double evalDiff, List<String> pvLine) {
    // Lightweight heuristic: if eval dropped significantly, threat is high
    if (evalDiff < -1.0) return 'High';
    if (evalDiff < -0.5) return 'Medium';
    return 'Low';
  }

  static String _determinePositionStyle(
    String move,
    List<String> threats,
    double diff,
  ) {
    if (threats.isNotEmpty || diff > 0.8) {
      return 'Attacking';
    }
    if (move.contains('k') || move.contains('g1') || move.contains('g8')) {
      return 'Defensive';
    }
    return 'Positional';
  }
}
