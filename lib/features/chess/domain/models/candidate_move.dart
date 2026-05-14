import 'package:flutter/foundation.dart';

/// Represents an engine-evaluated candidate variation emitted during Multi-PV search cycles.
@immutable
class CandidateMove {
  final int multipvIndex;
  final String uciMove;
  final double evaluation;
  final List<String> fullPv;

  const CandidateMove({
    required this.multipvIndex,
    required this.uciMove,
    required this.evaluation,
    this.fullPv = const [],
  });

  @override
  String toString() {
    return 'CandidateMove(multipv: $multipvIndex, move: $uciMove, eval: ${evaluation.toStringAsFixed(2)})';
  }
}
