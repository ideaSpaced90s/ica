// ignore_for_file: avoid_print

import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/data/tutorial_lessons.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_lesson.dart';

void main() {
  test('debug chapter 37', () {
    final lesson = TutorialLessonsDatabase.lessons.firstWhere((l) => l.chapterId == 37);
    final board = chess_lib.Chess();
    board.load(lesson.setupFen);
    print('Initial FEN: ${board.fen}');

    for (var i = 0; i < lesson.steps.length; i++) {
      final step = lesson.steps[i];
      if (step.resetToFen != null) {
        board.load(step.resetToFen!);
        print('Step $i (reset): FEN is now ${board.fen}');
      }

      final move = step.scriptedMove ??
          (step.type == TutorialStepType.awaitMove ? step.expectedMove : null);
      if (move == null) {
        print('Step $i: dialogue: "${step.dialogue}" (No move)');
        continue;
      }

      final from = move.substring(0, 2);
      final to = move.substring(2, 4);
      final promotion = move.length > 4 ? move.substring(4, 5) : 'q';

      final legalMoves = board.generate_moves().map((m) => board.move_to_san(m)).toList();
      final uciMoves = board.generate_moves().map((m) {
        final f = chess_lib.Chess.SQUARES.keys.firstWhere((k) => chess_lib.Chess.SQUARES[k] == m.from);
        final t = chess_lib.Chess.SQUARES.keys.firstWhere((k) => chess_lib.Chess.SQUARES[k] == m.to);
        return '$f$t';
      }).toList();

      print('Step $i: trying move $move. Turn: ${board.turn.toString().substring(board.turn.toString().length - 5)}. Legal SAN: $legalMoves. Legal UCI: $uciMoves');

      final result = board.move({
        'from': from,
        'to': to,
        'promotion': promotion,
      });

      if (!result) {
        print('FAILED Step $i: $move (dialogue: "${step.dialogue}")');
        print('Current FEN: ${board.fen}');
        break;
      } else {
        print('Step $i: $move succeeded. FEN: ${board.fen}');
      }
    }
  });
}
