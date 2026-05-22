import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/domain/chess_game.dart';
import 'package:kingslayer_chess/features/chess/services/position_context_builder.dart';
import 'package:kingslayer_chess/features/chess/services/prompt_builder.dart';

void main() {
  group('PositionContextBuilder Tests', () {
    test('Classification of move quality', () {
      final game = ChessGame();

      final contextPos = PositionContextBuilder.build(
        move: 'e2e4',
        currentEval: 1.2,
        previousEval: 0.3,
        game: game,
      );
      expect(contextPos.quality, 'Strong');

      final contextBrilliant = PositionContextBuilder.build(
        move: 'e2e4',
        currentEval: 2.5,
        previousEval: 0.5,
        game: game,
      );
      expect(contextBrilliant.quality, 'Brilliant');

      final contextBlunder = PositionContextBuilder.build(
        move: 'e2e4',
        currentEval: -1.5,
        previousEval: 1.0,
        game: game,
      );
      expect(contextBlunder.quality, 'Blunder');
    });

    test('Game phase detection', () {
      final game = ChessGame(); // Start position
      final contextOpening = PositionContextBuilder.build(
        move: 'e2e4',
        currentEval: 0.3,
        previousEval: 0.3,
        game: game,
      );
      expect(contextOpening.gamePhase, 'Opening');
    });

    test('PromptBuilder Gemma 3 construction', () {
      final game = ChessGame();
      final context = PositionContextBuilder.build(
        move: 'e2e4',
        currentEval: 0.4,
        previousEval: 0.2,
        game: game,
      );

      final prompt = context.toPromptString();
      expect(prompt, contains('Board State:'));
      expect(prompt, contains('Last Move Played:'));
      expect(prompt, contains('Analysis:'));

      // Let's test PromptBuilder itself
      final gemmaPrompt = PromptBuilder.buildCommentaryPrompt(context: context);
      expect(gemmaPrompt, contains('<start_of_turn>system'));
      expect(gemmaPrompt, contains('Identity: You are GM Bard'));
      expect(gemmaPrompt, contains('<start_of_turn>user'));
      expect(gemmaPrompt, contains('<start_of_turn>model'));
    });
  });
}
