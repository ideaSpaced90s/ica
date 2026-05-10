import 'package:flutter/foundation.dart';

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
  });

  @override
  String toString() {
    return 'PositionContext(move: $move, eval: $evaluation, diff: $evalDiff, Q: $quality, Phase: $gamePhase)';
  }

  /// Converts the context into a compact string format for the LLM.
  String toPromptString() {
    final buffer = StringBuffer();
    buffer.write('Current move is $move. ');
    buffer.write('Evaluation is ${evaluation.toStringAsFixed(1)}. ');
    buffer.write('This move is considered $quality. ');
    if (bestMove != null) {
      buffer.write('The engine preferred $bestMove. ');
    }
    buffer.write('Game is in $gamePhase phase. ');
    if (moveTypes.isNotEmpty) {
      buffer.write('Move types: ${moveTypes.join(", ")}. ');
    }
    if (pvLine.isNotEmpty) {
      buffer.write('Plan: ${pvLine.take(2).join(", ")}. ');
    }
    buffer.write('Threat level is $threatLevel.');
    return buffer.toString();
  }
}
