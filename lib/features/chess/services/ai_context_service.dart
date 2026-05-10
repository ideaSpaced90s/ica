import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chess_game.dart';
import '../domain/models/position_context.dart';
import 'position_context_builder.dart';
import 'prompt_builder.dart';

class AiContextService {
  PositionContext? _lastContext;
  PositionContext? get lastContext => _lastContext;

  /// Builds a new context and returns the generated prompt.
  String generateCommentaryPrompt({
    required String move,
    required double currentEval,
    required double previousEval,
    required ChessGame game,
    String? bestMove,
    List<String> pvLine = const [],
  }) {
    _lastContext = PositionContextBuilder.build(
      move: move,
      currentEval: currentEval,
      previousEval: previousEval,
      game: game,
      bestMove: bestMove,
      pvLine: pvLine,
    );

    return PromptBuilder.buildCommentaryPrompt(_lastContext!);
  }
}

final aiContextServiceProvider = Provider((ref) => AiContextService());
