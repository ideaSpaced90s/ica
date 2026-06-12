import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:kingslayer_chess/src/rust/api/context.dart';
import 'package:kingslayer_chess/src/rust/api/humanizer.dart';
import 'package:kingslayer_chess/src/rust/api/threats.dart';
import '../domain/chess_game.dart';
import '../domain/models/position_context.dart';
import '../domain/models/candidate_move.dart';
import '../domain/models/precomputed_rust_context.dart';

class PositionContextBuilder {
  static List<String> _humanizeUciSequence(String startFen, List<String> uciMoves, {bool isChess960 = false}) {
    if (uciMoves.isEmpty) return [];
    final List<String> humanized = [];
    try {
      final board = chess_lib.Chess.fromFEN(startFen);
      for (final uci in uciMoves) {
        if (uci.length < 4) break;
        final from = uci.substring(0, 2);
        final to = uci.substring(2, 4);
        final promo = uci.length > 4 ? uci.substring(4) : '';
        
        final fenBefore = board.fen;
        String label = uci;
        try {
          label = humanizeMoveRust(fenBefore: fenBefore, moveUci: uci, isChess960: isChess960);
        } catch (e) {
          debugPrint('ContextBuilder: Error humanizing move $uci in sequence: $e');
        }
        humanized.add(label);

        final moved = board.move({
          'from': from,
          'to': to,
          if (promo.isNotEmpty) 'promotion': promo,
        });
        if (!moved) {
          break;
        }
      }
    } catch (e) {
      debugPrint('ContextBuilder: Error simulating sequence: $e');
    }
    return humanized.isEmpty ? uciMoves : humanized;
  }

  static Future<PositionContext> build({
    required String move,
    required double currentEval,
    required double previousEval,
    required ChessGame game,
    String? bestMove,
    List<String> pvLine = const [],
    List<CandidateMove> candidates = const [],
    PrecomputedRustContext? precomputed,
  }) async {
    final evalDiff = currentEval - previousEval;
    final quality = _classifyQuality(evalDiff);

    String moveDescription;
    List<String> tacticalThreats;
    String gamePhase;

    if (precomputed != null) {
      moveDescription = precomputed.moveDescription;
      tacticalThreats = precomputed.tacticalThreats;
      gamePhase = precomputed.gamePhase;
    } else {
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

      final results = await Future.wait([
        Future(() {
          try {
            return humanizeMoveRust(fenBefore: fenBefore, moveUci: move, isChess960: game.isChess960);
          } catch (e) {
            debugPrint('ContextBuilder: Error calling humanizeMoveRust: $e');
            return move;
          }
        }),
        Future(() {
          try {
            return analyzeTacticalThreats(fen: game.fen, isChess960: game.isChess960);
          } catch (e) {
            debugPrint('ContextBuilder: Error calling analyzeTacticalThreats: $e');
            return <String>[];
          }
        }),
        Future(() => _detectGamePhase(game)),
      ]);

      moveDescription = results[0] as String;
      tacticalThreats = results[1] as List<String>;
      gamePhase = results[2] as String;
    }

    final isBestMove = _compareMoves(move, bestMove);
    final threatLevel = _calculateThreatLevel(evalDiff, pvLine);
    final positionStyle = _determinePositionStyle(move, tacticalThreats, evalDiff);

    // Humanize recommended bestMove at current board FEN
    String? humanBestMove;
    if (bestMove != null) {
      try {
        humanBestMove = humanizeMoveRust(fenBefore: game.fen, moveUci: bestMove, isChess960: game.isChess960);
      } catch (e) {
        humanBestMove = bestMove;
      }
    }

    // Humanize pvLine at current board FEN
    final humanizedPvLine = _humanizeUciSequence(game.fen, pvLine, isChess960: game.isChess960);

    // Humanize candidates list
    final List<CandidateMove> humanizedCandidates = [];
    for (final c in candidates) {
      String humanMove = c.uciMove;
      try {
        humanMove = humanizeMoveRust(fenBefore: game.fen, moveUci: c.uciMove, isChess960: game.isChess960);
      } catch (e) {
        // fallback
      }
      
      final humanPv = _humanizeUciSequence(game.fen, c.fullPv, isChess960: game.isChess960);
      
      humanizedCandidates.add(CandidateMove(
        multipvIndex: c.multipvIndex,
        uciMove: humanMove,
        evaluation: c.evaluation,
        fullPv: humanPv,
      ));
    }

    return PositionContext(
      move: move,
      moveDescription: moveDescription,
      evaluation: currentEval,
      evalDiff: evalDiff,
      quality: quality,
      bestMove: humanBestMove,
      isBestMove: isBestMove,
      gamePhase: gamePhase,
      tacticalThreats: tacticalThreats,
      threatLevel: threatLevel,
      positionStyle: positionStyle,
      pvLine: humanizedPvLine,
      candidates: humanizedCandidates,
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
        isChess960: game.isChess960,
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
