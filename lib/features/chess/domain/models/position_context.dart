import 'package:flutter/foundation.dart';
import 'candidate_move.dart';

/// Represents the structured context of a chess position for the AI to interpret.
@immutable
class PositionContext {
  final String move;
  final double evaluation;
  final double evalDiff;
  final String quality;
  final String? bestMove;
  final bool isBestMove;
  final String gamePhase;
  final List<String> moveTypes; // e.g., Capture, Check, Castling
  final String threatLevel;
  final String positionStyle;
  final List<String> pvLine;
  final List<CandidateMove> candidates;

  const PositionContext({
    required this.move,
    required this.evaluation,
    required this.evalDiff,
    required this.quality,
    this.bestMove,
    required this.isBestMove,
    required this.gamePhase,
    this.moveTypes = const [],
    required this.threatLevel,
    required this.positionStyle,
    this.pvLine = const [],
    this.candidates = const [],
  });

  @override
  String toString() {
    return 'PositionContext(move: $move, eval: $evaluation, diff: $evalDiff, Q: $quality, Phase: $gamePhase)';
  }

  /// Converts the context into a compact string format for the LLM.
  String toPromptString() {
    final buffer = StringBuffer();
    buffer.write('[BOARD INTEL]\n');
    buffer.write('- Last Move: $move\n');
    buffer.write('- Evaluation: ${evaluation.toStringAsFixed(1)}\n');
    buffer.write('- Quality: $quality\n');
    if (bestMove != null) {
      buffer.write('- ENGINE_RECOMMENDATION: $bestMove\n');
    }
    buffer.write('- Game Phase: $gamePhase\n');
    if (moveTypes.isNotEmpty) {
      buffer.write('- Events: ${moveTypes.join(", ")}\n');
    }
    if (pvLine.isNotEmpty) {
      buffer.write('- ENGINE_PLAN (PV): ${pvLine.take(5).join(", ")}\n');
    }
    buffer.write('- Threat Level: $threatLevel\n');
    buffer.write('- Position Style: $positionStyle\n');
    if (candidates.isNotEmpty) {
      buffer.write('- CANDIDATE_MOVES:\n');
      for (final c in candidates) {
        buffer.write('  * Move ${c.multipvIndex}: ${c.uciMove} (Eval: ${c.evaluation.toStringAsFixed(1)}), PV Path: ${c.fullPv.take(4).join(" -> ")}\n');
      }
    }
    return buffer.toString();
  }
}
