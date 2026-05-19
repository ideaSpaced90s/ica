import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chess_game.dart';
import '../domain/models/position_context.dart';
import '../domain/models/candidate_move.dart';
import '../data/saved_game.dart';
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
    List<CommentaryEntry> chatHistory = const [],
    List<CandidateMove> candidates = const [],
  }) {
    _lastContext = PositionContextBuilder.build(
      move: move,
      currentEval: currentEval,
      previousEval: previousEval,
      game: game,
      bestMove: bestMove,
      pvLine: pvLine,
      candidates: candidates,
    );

    final basePrompt = PromptBuilder.buildCommentaryPrompt(_lastContext!);

    if (chatHistory.isEmpty) return basePrompt;

    final historyStr = chatHistory.reversed
        .take(6)
        .toList()
        .reversed
        .map((e) {
          final role = e.isUser ? 'User' : 'Assistant';
          return '$role: ${e.text}';
        })
        .join('\n');

    return '$basePrompt\n\nRecent Conversation:\n$historyStr';
  }
}

final aiContextServiceProvider = Provider((ref) => AiContextService());
