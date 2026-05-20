import 'package:flutter/foundation.dart';
import 'candidate_move.dart';

/// Represents the structured context of a chess position for the AI to interpret.
@immutable
class PositionContext {
  final String move;
  final String moveDescription;
  final double evaluation;
  final double evalDiff;
  final String quality;
  final String? bestMove;
  final bool isBestMove;
  final String gamePhase;
  final List<String> tacticalThreats; // e.g. Pinned pieces, forks, hanging pieces
  final String threatLevel;
  final String positionStyle;
  final List<String> pvLine;
  final List<CandidateMove> candidates;

  const PositionContext({
    required this.move,
    required this.moveDescription,
    required this.evaluation,
    required this.evalDiff,
    required this.quality,
    this.bestMove,
    required this.isBestMove,
    required this.gamePhase,
    this.tacticalThreats = const [],
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
    buffer.write('Board State:\n');
    buffer.write('- Last Move Played: $moveDescription\n');
    buffer.write('- Analysis: The last move was a $quality move.\n');
    if (bestMove != null) {
      buffer.write('- Recommendation: Consider playing $bestMove.\n');
    }
    buffer.write('- Game Phase: $gamePhase\n');
    
    if (tacticalThreats.isNotEmpty) {
      buffer.write('- Tactical Alerts:\n');
      for (final threat in tacticalThreats) {
        buffer.write('  * $threat\n');
      }
    } else {
      buffer.write('- Tactical Alerts: None detected.\n');
    }

    if (pvLine.isNotEmpty) {
      buffer.write('- Recommended Plan: ${pvLine.take(5).join(", ")}\n');
    }
    buffer.write('- Threat Level: $threatLevel\n');
    buffer.write('- Position Style: $positionStyle\n');
    
    if (candidates.isNotEmpty) {
      buffer.write('- Candidate Moves:\n');
      for (final c in candidates) {
        buffer.write('  * Option ${c.multipvIndex}: Move ${c.uciMove}, continuation: ${c.fullPv.take(4).join(" -> ")}\n');
      }
    }
    return buffer.toString();
  }
}
